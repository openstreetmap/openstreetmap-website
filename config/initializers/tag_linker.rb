# frozen_string_literal: true

require "tag_linker"

TagLinker.init(
  :tag2link => Rails.root.join("node_modules/tag2link/index.json"),
  :wiki_pages => Rails.root.join("config/wiki_pages.yml")
)
