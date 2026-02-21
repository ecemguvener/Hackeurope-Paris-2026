# frozen_string_literal: true

module TextCleaner
  # "exam-\nple" → "example"
  HYPHEN_BREAK = /(\w)-\n(\w)/

  # 3+ consecutive newlines → 2
  MULTIPLE_BLANKS = /\n{3,}/

  # Trailing spaces on each line
  TRAILING_SPACE = / +$/

  def self.clean(text)
    return "" if text.blank?

    text
      .gsub(HYPHEN_BREAK, '\1\2')
      .gsub(TRAILING_SPACE, "")
      .gsub(MULTIPLE_BLANKS, "\n\n")
      .strip
  end
end
