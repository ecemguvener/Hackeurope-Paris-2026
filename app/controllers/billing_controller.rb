class BillingController < ApplicationController
  def show
    @company_id = BillingService.company_id
    @stub_mode  = BillingService.stub_mode?
    @summary    = BillingService.usage_summary(@company_id)
  end
end
