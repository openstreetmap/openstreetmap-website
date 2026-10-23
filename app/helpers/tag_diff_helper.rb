# frozen_string_literal: true

module TagDiffHelper
  def tag_diff(new_tags, old_tags)
    new_tags ||= {}
    old_tags ||= {}

    (new_tags.keys | old_tags.keys).sort.filter_map do |key|
      if new_tags.key?(key) && old_tags.key?(key)
        { :type => "modified", :key => key, :old_value => old_tags[key], :new_value => new_tags[key] } if new_tags[key] != old_tags[key]
      elsif new_tags.key?(key)
        { :type => "added", :key => key, :old_value => nil, :new_value => new_tags[key] }
      else
        { :type => "removed", :key => key, :old_value => old_tags[key], :new_value => nil }
      end
    end
  end
end
