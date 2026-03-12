# frozen_string_literal: true

namespace :i18n do
  desc "List keys missing in non-base locales"
  task :unmigrated_keys => :environment do
    require "i18n/tasks"

    i18n = I18n::Tasks::BaseTask.new
    unused_map = Hash.new { |h, k| h[k] = [] }
    base_locale = i18n.base_locale.to_s
    i18n.locales.each do |locale|
      i18n.unused_tree(:locale => locale)[locale]&.depth_first do |node|
        unused_map[node.full_key.split(".", 2)[1]] << locale unless node.children?
      end
    end
    unmigrated_keys = unused_map
                      .reject { |_, locales| locales.include?(base_locale) }
                      .transform_values { |locales| locales.sort.join(" ") }
                      .sort_by { |key, _| key }
                      .to_h
    puts unmigrated_keys.to_yaml
    exit unmigrated_keys.keys.size
  end
end
