# frozen_string_literal: true

require Rails.root.join("lib/tag2link")

Tag2link.load(Rails.root.join("node_modules/tag2link/index.json"))
