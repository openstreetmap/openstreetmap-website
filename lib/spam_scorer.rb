# frozen_string_literal: true

class SpamScorer
  SPAMMY_PHRASES = [
    "Business Description:", "Additional Keywords:"
  ].freeze

  def initialize(text)
    @text = text
  end

  def score
    link_count = 0
    link_size = 0

    doc = Nokogiri::HTML(text.to_html)

    if doc.content.empty?
      link_proportion = 0
    else
      doc.xpath("//a").each do |link|
        link_count += 1
        link_size += link.content.length
      end

      link_proportion = link_size.to_f / doc.content.length
    end

    spammy_phrases = SPAMMY_PHRASES.count do |phrase|
      doc.content.include?(phrase)
    end

    ([link_proportion - 0.2, 0.0].max * 200) +
      (link_count * 40) +
      (spammy_phrases * 40)
  end

  private

  attr_reader :text
end
