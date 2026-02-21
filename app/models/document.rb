class Document < ApplicationRecord
  belongs_to :user
  has_one_attached :file

  validates :user, presence: true

  TRANSFORMATION_STYLES = [
    { key: "simplified", title: "Simplified", description: "Shorter sentences, clearer structure" },
    { key: "bullet_points", title: "Bullet Points", description: "Key information as scannable bullets" },
    { key: "plain_language", title: "Plain Language", description: "Jargon replaced with everyday words" },
    { key: "restructured", title: "Restructured", description: "Reorganized for easier reading flow" }
  ].freeze

  def transformation_versions
    TRANSFORMATION_STYLES.map do |style|
      content = transformations&.dig(style[:key], "content")
      style.merge(content: content)
    end
  end

  def transformations_ready?
    transformations.present? && transformations.values.any? { |v| v["content"].present? }
  end
end
