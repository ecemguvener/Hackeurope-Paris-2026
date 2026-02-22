# frozen_string_literal: true

module Api
  module V1
    class InteractionsController < BaseController
      def create
        interaction = current_user.interactions.build(interaction_params)

        if interaction.save
          render json: { id: interaction.id, created_at: interaction.created_at }, status: :created
        else
          render json: { error: interaction.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def interaction_params
        params.permit(:page_url, :page_title, :action_type, :input_text, :output_text, :style, metadata: {})
      end
    end
  end
end
