# frozen_string_literal: true

class Interaction < ApplicationRecord
  belongs_to :user

  validates :action_type, presence: true
end
