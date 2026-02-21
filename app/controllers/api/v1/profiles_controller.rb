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
          updates[:profile] = current_user.profile.merge(params[:profile].permit!.to_h)
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
    end
  end
end
