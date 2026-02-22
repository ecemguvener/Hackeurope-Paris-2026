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
    typing_metrics_json = params[:typing_metrics_json].to_s

    return_path = safe_return_path(params[:return_to])

    if retyped_text.blank? || difficulty.blank?
      redirect_to return_path, alert: "Please complete the reading assessment form."
      return
    end

    parsed = ReadingTestAnalyser.call(
      current_user,
      retyped_text: retyped_text,
      self_described_difficulty: difficulty,
      time_taken_seconds: time_taken.positive? ? time_taken : 1,
      typing_metrics_json: typing_metrics_json
    )

    profile = (current_user.profile || {}).deep_dup
    style_key = normalize_style_key(parsed["recommended_style"] || profile["recommended_style"])
    profile["recommended_style"] = style_key if style_key.present?
    profile["assessment_completed"] = true
    profile["assessment_completed_at"] = Time.current.iso8601

    updates = { profile: profile }
    updates[:preferred_style] = Document.style_for_key(style_key)&.dig(:title) if style_key.present?
    current_user.update!(updates)

    redirect_to return_path, notice: "Reading assessment saved. Personalization is now stronger."
  rescue => e
    Rails.logger.error("Reading assessment failed: #{e.message}")
    redirect_to return_path, alert: "Could not save the assessment right now."
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

  private

  def normalize_style_key(raw_style)
    key = raw_style.to_s
    return key if Document.style_keys.include?(key)

    case key
    when "bullet"
      "bullet_points"
    when "simple"
      "simplified"
    when "chunked", "structured"
      "restructured"
    when "plain"
      "plain_language"
    else
      nil
    end
  end

  def safe_return_path(value)
    path = value.to_s
    return profile_path unless path.start_with?("/")
    return profile_path if path.start_with?("//")

    path
  end
end
