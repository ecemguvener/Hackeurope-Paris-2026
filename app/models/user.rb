class User < ApplicationRecord
  has_many :documents, dependent: :destroy
  has_many :interactions, dependent: :destroy

  validates :name, presence: true

  before_create :generate_api_token

  private

  def generate_api_token
    self.api_token ||= SecureRandom.hex(32)
  end
end
