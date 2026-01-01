# frozen_string_literal: true

module SpamScorer
  class RichText
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

      comparable_content = to_comparable_form(doc.content)
      spammy_phrases = SpammyPhrase.pluck(:phrase).count do |phrase|
        comparable_content.include?(to_comparable_form(phrase))
      end

      ([link_proportion - 0.2, 0.0].max * 200) +
        (link_count * 40) +
        (spammy_phrases * 40)
    end

    private

    attr_reader :text

    def to_comparable_form(str)
      str.downcase(:fold).unicode_normalize(:nfkc).gsub(/\s+/u, " ")
    end
  end
end
