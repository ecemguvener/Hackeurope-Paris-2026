# frozen_string_literal: true

module Api
  module V1
    class ProfilesController < BaseController
      wrap_parameters false

      def show
        render json: {
          name: current_user.name,
          preferred_style: current_user.preferred_style,
          profile: current_user.profile
        }
      end

      def update
        updates = {}
        updates[:preferred_style] = params[:preferred_style] if params.key?(:preferred_style)

        if params.key?(:profile) && params[:profile].is_a?(ActionController::Parameters)
          updates[:profile] = current_user.profile.merge(permitted_profile_params)
        end

        if current_user.update(updates)
          render json: {
            name: current_user.name,
            preferred_style: current_user.preferred_style,
            profile: current_user.profile
          }
        else
          render json: { error: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def permitted_profile_params
        params[:profile].permit(
          :sentence_length,
          :font_preference,
          :simplify_jargon,
          :reading_speed,
          :comprehension_score,
          :main_struggle,
          :has_dyslexia_pattern,
          :recommended_style,
          :assessment,
          :preferred_style,
          style_weights: {}
        ).to_h
      end
    end
  end
end
