class ProfilesController < ApplicationController
  def show
    @user = current_user
    @documents = @user.documents.with_attached_file.order(created_at: :desc)
  end
end
