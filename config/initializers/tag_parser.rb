# frozen_string_literal: true

require "tag_parser"

TagParser.init(
  :tag2link => Rails.root.join("node_modules/tag2link/index.json"),
  :wiki_pages => Rails.root.join("config/wiki_pages.yml")
)
