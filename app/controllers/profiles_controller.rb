class ProfilesController < ApplicationController
  def show
    @user = current_user
    @documents = @user.documents.with_attached_file.order(created_at: :desc)
  end

  def assessment
    # Pull quick inputs from the form and keep defaults safe.
    retyped_text = params[:retyped_text].to_s
    difficulty = params[:self_described_difficulty].to_s
    time_taken = params[:time_taken_seconds].to_f

    if retyped_text.blank? || difficulty.blank?
      redirect_to profile_path, alert: "Please complete the reading assessment form."
      return
    end

    ReadingTestAnalyser.call(
      current_user,
      retyped_text: retyped_text,
      self_described_difficulty: difficulty,
      time_taken_seconds: time_taken.positive? ? time_taken : 1
    )

    redirect_to profile_path, notice: "Reading assessment saved. Personalization is now stronger."
  rescue => e
    Rails.logger.error("Reading assessment failed: #{e.message}")
    redirect_to profile_path, alert: "Could not save the assessment right now."
  end

  def readability
    mode = params[:mode].to_s
    unless %w[standard strong].include?(mode)
      redirect_back fallback_location: profile_path, alert: "Invalid readability mode."
      return
    end

    # Keep this tiny: one profile flag controls how intense formatting gets.
    profile = (current_user.profile || {}).deep_dup
    profile["readability_mode"] = mode
    current_user.update!(profile: profile)

    redirect_back fallback_location: profile_path, notice: "Readability mode set to #{mode.titleize}."
  end
end
