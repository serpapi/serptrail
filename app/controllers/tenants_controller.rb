class TenantsController < ApplicationController
  def edit
    @tenant = Tenant.instance
  end

  def update
    @tenant = Tenant.instance
    if @tenant.update(tenant_params)
      redirect_to edit_settings_path, notice: "Settings saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def tenant_params
    params.expect(tenant: [ :serpapi_key, :openai_api_key ])
  end
end
