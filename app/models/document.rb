class Document < ApplicationRecord
  belongs_to :user
  has_one_attached :file

  TRANSFORMATION_STYLES = [
    { key: "simplified", title: "Simplified", description: "Shorter sentences, clearer structure" },
    { key: "bullet_points", title: "Bullet Points", description: "Key information as scannable bullets" },
    { key: "plain_language", title: "Plain Language", description: "Jargon replaced with everyday words" },
    { key: "restructured", title: "Restructured", description: "Reorganized for easier reading flow" }
  ].freeze

  validates :user, presence: true
  validates :selected_version, inclusion: { in: 1..TRANSFORMATION_STYLES.length }, allow_nil: true

  def transformation_versions
    TRANSFORMATION_STYLES.map do |style|
      content = transformations&.dig(style[:key], "content")
      style.merge(content: content)
    end
  end

  def self.style_keys
    TRANSFORMATION_STYLES.map { |style| style[:key] }
  end

  def self.style_for_key(key)
    TRANSFORMATION_STYLES.find { |style| style[:key] == key.to_s }
  end

  def self.selected_version_for_style(key)
    index = TRANSFORMATION_STYLES.index { |style| style[:key] == key.to_s }
    index ? index + 1 : nil
  end

  def transformations_ready?
    transformations.present? && transformations.values.any? { |v| v["content"].present? }
  end

  def selected_style
    return nil unless selected_version&.between?(1, TRANSFORMATION_STYLES.length)

    TRANSFORMATION_STYLES[selected_version - 1]
  end

  def selected_content
    style = selected_style
    return nil unless style

    transformations&.dig(style[:key], "content")
  end

  def version_selected?
    selected_version.present? && selected_version.positive?
  end
end
