class AppContext < RubyLLM::Tool
  include Rails.application.routes.url_helpers

  desc <<~TEXT
    Fetches extra internal guidance for known SerpTrail app context/behaviors.

    Call this before answering if the user is asking about anything relating to
    a specific app context or if a response would be enhanced by having extra
    guidance or specifics about an app context.

    Known contexts:
      * add-site: Anything relating to adding or tracking a new site
      * sites: Anything relating to editing or managing sites
      * add-keyword: Anything relating to creating/adding keywords to track
      * keywords: Anything relating to editing, or managing keywords
      * views: Anything relating to creating/adding, editing, or managing
               custom views/charts
      * settings: Anything relating to configuring or managing SerpTrail
                  settings, including API keys, user accounts, and preferences
  TEXT

  params do
    string :context_id, description: "The ID of the context to fetch guidance for"
  end

  def execute(context_id:)
    case context_id
    when "add-site"
      <<~TEXT
        Add site route: `#{new_site_path}`
        How to get there:
          * go to the "Sites" page from the top menu, then click "Add"
        Fields:
          * Name [required]
          * Domain [required]
          * Match subdomains [optional, defaults to false]
      TEXT
    when "sites"
      <<~TEXT
        Sites index route: `#{sites_path}`
        How to get there:
          * go to the "Sites" page from the top menu, then click on a site
        What to do there:
          * view the site's tracked keywords and their current positions
          * edit the site's name, domain, or subdomain matching setting
          * delete the site and all its associated keywords and checks
      TEXT
    when "add-keyword"
      <<~TEXT
        Add keyword (not specific to a single site) route: `#{new_keyword_path}`
        How to get there:
          * go to the "Keywords" page from the top menu, then click "Add"; OR
          * if viewing a specific site, click "Add" in the top right corner
        Fields:
          * Query [required]
          * Locations [optional, defaults to US]
          * Check frequency [optional, defaults to daily]
          * Sites to track [optional, can be set later] [not visible if adding
            from the site page]
      TEXT
    when "keywords"
      <<~TEXT
        Keywords index (not specific to a single site) route: `#{keywords_path}`
        How to get there:
          * go to the "Keywords" page from the top menu, then click on a
            keyword; OR
          * if viewing a specific site, click on a keyword in the site's
            keyword list
        What to do there:
          * see a list of the search runs for that keyword
          * see the latest (and historic) results for the keyword by location
          * trigger a manual check for the keyword
          * edit the keyword's query, locations, check frequency, and tracked
            sites
          * view a specific site's tracking history for that keyword
      TEXT
    when "views"
      <<~TEXT
        Views index route: `#{views_path}`
        How to get there:
          * go to the "Views" page from the top menu, then click "Add"
        What to do there:
          * create a custom view containing tracked keywords and their
            positions
          * choose which sites and keywords to include in the view
          * choose which locations to include in the view
      TEXT
    when "settings"
      <<~TEXT
        Settings route: `#{settings_path}`
        How to get there:
          * go to the "Settings" page from the top menu (the gear icon)
        What to do there:
          * configure your SerpApi API key
          * configure your OpenAI API key
      TEXT
    else
      "No specific guidance available for this context ID."
    end
  end
end
