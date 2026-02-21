# frozen_string_literal: true

class BillingController < ApplicationController
  def show
    @summary = BillingService.usage_summary(current_user)
    @documents = current_user.documents.order(created_at: :desc).limit(10)
    @stub_mode = BillingService.stub_mode?
  end
end
