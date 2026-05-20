class Sites::KeywordsController < ApplicationController
  before_action :set_site
  before_action :set_keyword_target, only: %i[show edit update destroy check]

  def show
    @has_checks = @keyword_target.checks.exists?
    @checks_by_location = @keyword_target.checks
      .where(status: "success")
      .order(checked_at: :asc)
      .group_by(&:location)

    @location_stats = @keyword.locations.map do |location|
      checks   = (@checks_by_location[location] || []).sort_by(&:checked_at).reverse
      latest   = checks.first
      previous = checks.second
      change   = if latest&.position && previous&.position
        previous.position - latest.position
      end
      latest_ai = checks.find { |c| !c.ai_overview_present.nil? }
      { location: location, latest: latest, change: change, latest_ai: latest_ai }
    end
  end

  def new
    @keyword = Keyword.new(site: @site)
  end

  def import
    @keyword = Keyword.new(site: @site)

    if request.post?
      queries = import_params[:queries].to_s.lines.map(&:strip).reject(&:blank?).uniq
      locations = import_params[:locations] || [ "us" ]
      check_frequency = import_params[:check_frequency].presence || "daily"

      created = queries.count do |query|
        keyword = find_or_initialize_keyword(query, locations: locations, check_frequency: check_frequency)
        new_keyword = keyword.new_record?
        if keyword.save
          target = keyword.keyword_targets.find_or_create_by!(site: @site)
          created_tracking = new_keyword || target.previously_new_record?
          if created_tracking
            keyword.locations.each { |location| KeywordCheckJob.perform_later(keyword, location) }
            keyword.update_column(:last_checked_at, Time.current)
          end
          created_tracking
        end
      end

      skipped = queries.size - created
      notice = "#{created} #{"keyword".pluralize(created)} imported."
      notice += " #{skipped} skipped (already exist)." if skipped > 0
      redirect_to @site, notice: notice
    end
  end

  def create
    @keyword = find_or_initialize_keyword(keyword_params[:query], locations: keyword_params[:locations], check_frequency: keyword_params[:check_frequency])

    if @keyword.save
      @keyword_target = @keyword.keyword_targets.find_or_create_by!(site: @site)
      @keyword.locations.each { |location| KeywordCheckJob.perform_later(@keyword, location) }
      @keyword.update_column(:last_checked_at, Time.current)
      redirect_to @site
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @keyword.update(keyword_update_params)
      redirect_to @site, notice: "Keyword was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def check
    @keyword.locations.each { |location| KeywordCheckJob.perform_later(@keyword, location) }
    redirect_to @site, notice: "Ranking check queued for \"#{@keyword.query}\"."
  end

  def destroy
    @keyword_target.destroy!
    @keyword.destroy! if @keyword.keyword_targets.reload.none?
    redirect_to @site, notice: "Keyword was successfully deleted."
  end

  private

  def set_site
    @site = Site.find(params[:site_id])
  end

  def set_keyword_target
    @keyword_target = @site.keyword_targets.includes(:keyword).find_by!(keyword_id: params[:id])
    @keyword = @keyword_target.keyword
  end

  def find_or_initialize_keyword(query, locations:, check_frequency:)
    existing_target = @site.keyword_targets.joins(:keyword).find_by(keywords: { query: query })
    keyword = existing_target&.keyword || Keyword.find_by(query: query) || Keyword.new(query: query, site: @site)
    keyword.site ||= @site
    keyword.locations = locations if locations.present?
    keyword.check_frequency = check_frequency if check_frequency.present?
    keyword
  end

  def import_params
    params.expect(keyword: [ :queries, :check_frequency, locations: [] ])
  end

  def keyword_params
    params.expect(keyword: [ :query, :check_frequency, locations: [] ])
  end

  def keyword_update_params
    params.expect(keyword: [ :query, :check_frequency, locations: [] ])
  end
end
