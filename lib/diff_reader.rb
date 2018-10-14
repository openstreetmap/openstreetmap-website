##
# DiffReader reads OSM diffs and applies them to the database.
#
# Uses the streaming LibXML "Reader" interface to cut down on memory
# usage, so hopefully we can process fairly large diffs.
class DiffReader
  include ConsistencyValidations

  # maps each element type to the model class which handles it
  MODELS = {
    "node"     => Node,
    "way"      => Way,
    "relation" => Relation
  }.freeze

  ##
  # Construct a diff reader by giving it a bunch of XML +data+ to parse
  # in OsmChange format. All diffs must be limited to a single changeset
  # given in +changeset+.
  def initialize(data, changeset)
    @reader = XML::Reader.string(data)
    @changeset = changeset
    # document that's (re-)used to handle elements expanded out of the
    # diff processing stream.
    @doc = XML::Document.new
    @doc.root = XML::Node.new("osm")
  end

  ##
  # Reads the next element from the XML document. Checks the return value
  # and throws an exception if an error occurred.
  def read_or_die
    # NOTE: XML::Reader#read returns false for EOF and raises an
    # exception if an error occurs.
    @reader.read
  rescue LibXML::XML::Error => ex
    raise OSM::APIBadXMLError.new("changeset", xml, ex.message)
  end

  ##
  # An element-block mapping for using the LibXML reader interface.
  #
  # Since a lot of LibXML reader usage is boilerplate iteration through
  # elements, it would be better to DRY and do this in a block. This
  # could also help with error handling...?
  def with_element
    # if the start element is empty then don't do any processing, as
    # there won't be any child elements to process!
    unless @reader.empty_element?
      # read the first element
      read_or_die

      while @reader.node_type != 15 # end element
        # because we read elements in DOM-style to reuse their DOM
        # parsing code, we don't always read an element on each pass
        # as the call to @reader.next in the innermost loop will take
        # care of that for us.
        if @reader.node_type == 1 # element
          name = @reader.name
          attributes = {}

          if @reader.has_attributes?
            attributes[@reader.name] = @reader.value while @reader.move_to_next_attribute == 1

            @reader.move_to_element
          end

          yield name, attributes
        else
          read_or_die
        end
      end
    end
    read_or_die
  end

  ##
  # An element-block mapping for using the LibXML reader interface.
  #
  # Since a lot of LibXML reader usage is boilerplate iteration through
  # elements, it would be better to DRY and do this in a block. This
  # could also help with error handling...?
  def with_model
    with_element do |model_name, _model_attributes|
      model = MODELS[model_name]
      if model.nil?
        raise OSM::APIBadUserInput, "Unexpected element type #{model_name}, " \
                                       "expected node, way or relation."
      end
      # new in libxml-ruby >= 2, expand returns an element not associated
      # with a document. this means that there's no encoding parameter,
      # which means basically nothing works.
      expanded = @reader.expand

      # create a new, empty document to hold this expanded node
      new_node = @doc.import(expanded)
      @doc.root << new_node

      yield model, new_node
      @reader.next

      # remove element from doc - it will be garbage collected and the
      # rest of the document is re-used in the next iteration.
      @doc.root.child.remove!
    end
  end

  ##
  # Checks a few invariants. Others are checked in the model methods
  # such as save_ and delete_with_history.
  def check(model, xml, new)
    raise OSM::APIBadXMLError.new(model, xml) if new.nil?
    raise OSM::APIChangesetMismatchError.new(new.changeset_id, @changeset.id) unless new.changeset_id == @changeset.id
  end

  ##
  # Consume the XML diff and try to commit it to the database. This code
  # is *not* transactional, so code which calls it should ensure that the
  # appropriate transaction block is in place.
  #
  # On a failure to meet preconditions (e.g: optimistic locking fails)
  # an exception subclassing OSM::APIError will be thrown.
  def commit
    # data structure used for mapping placeholder IDs to real IDs
    ids = { :node => {}, :way => {}, :relation => {} }
    # placeholder_id -> model object to save
    # client_ids = { :node => {}, :way => {}, :relation => {} }
    # model -> xml array
    osm_changes = { :create => [], :modify => [], :delete => [] }
    # action -> attrs
    change_attributes = {}

    result = OSM::API.new.get_xml_doc
    result.root.name = "diffResult"

    # take the first element and check that it is an osmChange element
    @reader.read
    raise OSM::APIBadUserInput, "Document element should be 'osmChange'." if @reader.name != "osmChange"

    # classify changes by action and model
    with_element do |action_name, action_attributes|
      action_name_sym = action_name.to_sym
      raise OSM::APIChangesetActionInvalid, action_name unless osm_changes.include? action_name_sym

      action_elements = {}
      with_model do |model, xml|
        action_elements[model] ||= []
        action_elements[model].append xml
      end
      osm_changes[action_name_sym].append(action_elements)
      change_attributes[action_name_sym] ||= []
      change_attributes[action_name_sym].append action_attributes
    end
    # create
    osm_changes[:create].each do |action_group|
      action_group.each do |model, xml_arr|
        model_sym = model.to_s.downcase.to_sym
        wait_hash = {}
        xml_arr.each do |xml|
          new = model.from_xml_node(xml, true)
          check(model, xml, new)

          # when this element is saved it will get a new ID, so we save it
          # to produce the mapping which is sent to other elements.
          placeholder_id = xml["id"].to_i

          # when this element is saved it will get a new ID, so we save it
          # to produce the mapping which is sent to other elements.
          raise OSM::APIBadXMLError.new(model, xml) if placeholder_id.nil?

          # check if the placeholder ID has been given before and throw
          # an exception if it has - we can't create the same element twice.
          raise OSM::APIBadUserInput, "Placeholder IDs must be unique for created elements." if ids[model_sym].include?(placeholder_id) || wait_hash.include?(placeholder_id)

          wait_hash[placeholder_id] = new
        end
        until wait_hash.empty?
          temp_hash = wait_hash
          wait_hash = {}
          new_hash = {}
          first_relation_fail = nil
          temp_hash.each do |placeholder_id, new|
            if model_sym == :relation
              fail = new.fix_placeholders(ids)
              if fail.nil?
                new_hash[placeholder_id] = new
              elsif fail[0].downcase.to_sym == :relation
                first_relation_fail ||= fail
                wait_hash[placeholder_id] = new
              else
                raise OSM::APIBadUserInput, "Placeholder #{fail[0]} not found for reference #{fail[1]} in relation #{new.id.nil? ? placeholder_id : new.id}."
              end
            else
              new.fix_placeholders!(ids, placeholder_id)
              new_hash[placeholder_id] = new
            end
          end
          if new_hash.empty? && !first_relation_fail.nil?
            # Nothing to create, wait_hash not empty
            # just raise last exception
            p_id, super_relation = wait_hash.first
            raise OSM::APIBadUserInput, "Placeholder #{first_relation_fail[0]} not found for reference #{first_relation_fail[1]} in relation #{super_relation.id.nil? ? p_id : super_relation.id}."
          end
          model.create_with_history_bulk(new_hash.values, @changeset)
          new_hash.each do |placeholder_id, new|
            # save id map
            ids[model_sym][placeholder_id] = new.id
            # add the result to the document we're building for return.
            xml_result = XML::Node.new model.to_s.downcase
            xml_result["old_id"] = placeholder_id.to_s
            xml_result["new_id"] = new.id.to_s
            xml_result["new_version"] = new.version.to_s
            result.root << xml_result
          end
        end
        # retry to save relations one by one
        wait_hash.each do |placeholder_id, new|
          new.fix_placeholders!(ids, placeholder_id)
          # use bulk creation as single creation.
          # shouldn't use single creation method directly, for that some changeset updates may be lost.
          model.create_with_history_bulk([new], @changeset)
          # save id map
          ids[model_sym][placeholder_id] = new.id
          # add the result to the document we're building for return.
          xml_result = XML::Node.new model.to_s.downcase
          xml_result["old_id"] = placeholder_id.to_s
          xml_result["new_id"] = new.id.to_s
          xml_result["new_version"] = new.version.to_s
          result.root << xml_result
        end
      end
    end

    # modify
    osm_changes[:modify].each do |action_group|
      action_group.each do |model, xml_arr|
        all_pairs = []
        wait_pairs = []
        xml_arr.each do |xml|
          # get the new element from the XML payload
          new = model.from_xml_node(xml, false)
          check(model, xml, new)

          # if the ID is a placeholder then map it to the real ID
          model_sym = model.to_s.downcase.to_sym
          client_id = new.id
          is_placeholder = ids[model_sym].include? client_id
          id = is_placeholder ? ids[model_sym][client_id] : client_id

          # translate any placeholder IDs to their true IDs.
          new.fix_placeholders!(ids)
          new.id = id
          all_pairs.append [client_id, new]
          wait_pairs.append [client_id, new]
        end
        until wait_pairs.empty?
          new_hash = {}
          temp_pairs = []
          wait_pairs.each do |client_id, new|
            if new_hash.key? client_id
              temp_pairs.append [client_id, new]
            else
              new_hash[client_id] = new
            end
          end
          model.update_from_bulk(new_hash.values, @changeset)
          wait_pairs = temp_pairs
        end
        all_pairs.each do |client_id, new|
          xml_result = XML::Node.new model.to_s.downcase
          xml_result["old_id"] = client_id.to_s
          xml_result["new_id"] = new.id.to_s
          # version is updated in "old" through the update, so we must not
          # return new.version here but old.version!
          xml_result["new_version"] = new.version.to_s
          result.root << xml_result
        end
      end
    end

    # delete
    osm_changes[:delete].each_with_index do |action_group, group_idx|
      action_group.each do |model, xml_arr|
        new_hash = {}
        xml_arr.each do |xml|
          # delete doesn't have to contain a full payload, according to
          # the wiki docs, so we just extract the things we need.
          new_id = xml["id"].to_i
          raise OSM::APIBadXMLError.new(model, xml, "ID attribute is required") if new_id.nil?

          # if the ID is a placeholder then map it to the real ID
          model_sym = model.to_s.downcase.to_sym
          is_placeholder = ids[model_sym].include? new_id
          id = is_placeholder ? ids[model_sym][new_id] : new_id

          # build the "new" element by modifying the existing one
          new = model.new
          new.id = id
          new.changeset_id = xml["changeset"].to_i
          new.version = xml["version"].to_i
          check(model, xml, new)
          new_hash[new_id] = new
        end
        if_unused = change_attributes[:delete][group_idx]["if-unused"]
        skipped = model.delete_with_history_bulk!(new_hash.values, @changeset, if_unused)
        new_hash.each do |client_id, new|
          xml_result = XML::Node.new model.to_s.downcase
          xml_result["old_id"] = client_id.to_s
          if skipped.key? new.id
            xml_result["new_id"] = new.id.to_s
            xml_result["new_version"] = new.version.to_s
          end
          result.root << xml_result
        end
      end
    end
    # return the XML document to be rendered back to the client
    result
  end
end
