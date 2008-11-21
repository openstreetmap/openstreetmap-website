module ConsistencyValidations
  # Generic checks that are run for the updates and deletes of
  # node, ways and relations. This code is here to avoid duplication, 
  # and allow the extention of the checks without having to modify the
  # code in 6 places for all the updates and deletes. Some of these tests are 
  # needed for creates, but are currently not run :-( 
  # This will throw an exception if there is an inconsistency
  def check_consistency(old, new, user)
    if new.version != old.version
      raise OSM::APIVersionMismatchError.new(new.id, new.class.to_s, new.version, old.version)
    elsif new.changeset.nil?
      raise OSM::APIChangesetMissingError.new
    elsif new.changeset.user_id != user.id
      raise OSM::APIUserChangesetMismatchError.new
    elsif not new.changeset.is_open?
      raise OSM::APIChangesetAlreadyClosedError.new(new.changeset)
    end
  end
  
  # This is similar to above, just some validations don't apply
  def check_create_consistency(new, user)
    if new.changeset.nil?
      raise OSM::APIChangesetMissingError.new
    elsif new.changeset.user_id != user.id
      raise OSM::APIUserChangesetMismatchError.new
    elsif not new.changeset.is_open?
      raise OSM::APIChangesetAlreadyClosedError.new(new.changeset)
    end
  end
end
