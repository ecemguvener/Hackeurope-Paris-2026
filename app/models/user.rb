class User < ApplicationRecord
  has_many :documents, dependent: :destroy
  has_many :interactions, dependent: :destroy

  validates :name, presence: true
  validates :api_token, uniqueness: true, allow_nil: true

  before_create :assign_api_token

  private

  def assign_api_token
    self.api_token ||= loop do
      t = SecureRandom.hex(24)
      break t unless User.exists?(api_token: t)
    end
  end
end
