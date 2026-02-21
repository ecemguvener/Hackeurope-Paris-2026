class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # MVP: hardcoded demo user (no auth)
  def current_user
    @current_user ||= User.find_by(name: "Demo User")
  end
  helper_method :current_user
end
