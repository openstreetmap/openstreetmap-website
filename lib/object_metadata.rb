module ObjectMetadata
  def add_metadata_to_xml_node(el1, osm, changeset_cache, user_display_name_cache)
    el1['changeset'] = osm.changeset_id.to_s
    el1['redacted'] = osm.redaction.id.to_s if osm.redacted?
    el1['timestamp'] = osm.timestamp.xmlschema
    el1['version'] = osm.version.to_s
    el1['visible'] = osm.visible.to_s

    if changeset_cache.key?(osm.changeset_id)
      # use the cache if available
    else
      changeset_cache[osm.changeset_id] = osm.changeset.user_id
    end

    user_id = changeset_cache[osm.changeset_id]

    if user_display_name_cache.key?(user_id)
      # use the cache if available
    elsif osm.changeset.user.data_public?
      user_display_name_cache[user_id] = osm.changeset.user.display_name
    else
      user_display_name_cache[user_id] = nil
    end

    unless user_display_name_cache[user_id].nil?
      el1['user'] = user_display_name_cache[user_id]
      el1['uid'] = user_id.to_s
    end

    end
end
