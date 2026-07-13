class TenantsController < ApplicationController
  before_action :set_serpapi_credit_estimate

  def edit
    @tenant = Tenant.instance
  end

  def update
    @tenant = Tenant.instance
    if @tenant.update(tenant_params)
      redirect_to settings_path, notice: "Settings saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_serpapi_credit_estimate
    @serpapi_credit_estimate = SerpApiCreditEstimator.new
  end

  def tenant_params
    params.expect(tenant: [ :serpapi_key, :openai_api_key ])
  end
end
