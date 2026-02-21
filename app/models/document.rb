class Document < ApplicationRecord
  belongs_to :user
  has_one_attached :file

  validates :user, presence: true
end
