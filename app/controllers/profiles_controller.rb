class ProfilesController < ApplicationController
  def show
    @user = current_user
    @documents = @user.documents.order(created_at: :desc)
  end
end
