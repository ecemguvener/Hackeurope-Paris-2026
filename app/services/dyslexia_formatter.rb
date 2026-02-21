# frozen_string_literal: true

# Reformats clean text so it is easier to read for people with dyslexia.
# Rules:
#   - Long paragraphs are split into shorter chunks with blank lines between them.
#   - Obvious lists (lines starting with *, -, •, or a number) become bullet points.
#   - Detected headings get a "---" separator appended.
#   - Code blocks (``` or 4-space indent) are left untouched.
#   - Meaning is never altered.
class DyslexiaFormatter
  MAX_WORDS_PER_CHUNK = 50
  SECTION_SEPARATOR = "\n\n---\n\n"

  def self.format(text)
    new(text).format
  end

  def initialize(text)
    @text = text
  end

  def format
    return "" if @text.blank?

    @text
      .split(/\n\n+/)
      .map { |para| process(para) }
      .join("\n\n")
  end

  private

  def process(para)
    return para if code_block?(para)

    if list_like?(para)
      convert_to_bullets(para)
    elsif heading_like?(para)
      "#{para}#{SECTION_SEPARATOR}"
    elsif long?(para)
      chunk(para)
    else
      para
    end
  end

  def code_block?(para)
    para.start_with?("```") ||
      para.lines.all? { |l| l.match?(/\A    /) || l.strip.empty? }
  end

  def list_like?(para)
    lines = para.lines.map(&:strip).reject(&:empty?)
    return false if lines.length < 2

    bullet_count = lines.count { |l| l.match?(/\A[\*\-\•]|\A\d+[\.\)]/) }
    bullet_count >= 2 || (bullet_count.to_f / lines.length) >= 0.5
  end

  def convert_to_bullets(para)
    para.lines.filter_map do |line|
      stripped = line.strip
      next if stripped.empty?

      body = stripped
        .sub(/\A[\*\-\•]\s*/, "")
        .sub(/\A\d+[\.\)]\s*/, "")
      "- #{body}"
    end.join("\n")
  end

  def heading_like?(para)
    lines = para.lines.reject { |l| l.strip.empty? }
    return false unless lines.length == 1

    line = para.strip
    words = line.split
    words.length <= 8 &&
      line.length < 80 &&
      !line.end_with?(".", ",", ";", ":") &&
      !line.match?(/\A[-*•]/)
  end

  def long?(para)
    para.split.length > MAX_WORDS_PER_CHUNK
  end

  def chunk(para)
    para.split.each_slice(MAX_WORDS_PER_CHUNK).map { |words| words.join(" ") }.join("\n\n")
  end
end
