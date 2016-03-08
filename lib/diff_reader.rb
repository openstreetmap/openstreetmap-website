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
            while @reader.move_to_next_attribute == 1
              attributes[@reader.name] = @reader.value
            end

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
      raise OSM::APIBadUserInput.new("Unexpected element type #{model_name}, " +
                                     "expected node, way or relation.") if model.nil?
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
    unless new.changeset_id == @changeset.id
      raise OSM::APIChangesetMismatchError.new(new.changeset_id, @changeset.id)
    end
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

    # take the first element and check that it is an osmChange element
    @reader.read
    raise OSM::APIBadUserInput.new("Document element should be 'osmChange'.") if @reader.name != "osmChange"

    result = OSM::API.new.get_xml_doc
    result.root.name = "diffResult"

    # loop at the top level, within the <osmChange> element
    with_element do |action_name, action_attributes|
      if action_name == "create"
        # create a new element. this code is agnostic of the element type
        # because all the elements support the methods that we're using.
        with_model do |model, xml|
          new = model.from_xml_node(xml, true)
          check(model, xml, new)

          # when this element is saved it will get a new ID, so we save it
          # to produce the mapping which is sent to other elements.
          placeholder_id = xml["id"].to_i
          raise OSM::APIBadXMLError.new(model, xml) if placeholder_id.nil?

          # check if the placeholder ID has been given before and throw
          # an exception if it has - we can't create the same element twice.
          model_sym = model.to_s.downcase.to_sym
          raise OSM::APIBadUserInput.new("Placeholder IDs must be unique for created elements.") if ids[model_sym].include? placeholder_id

          # some elements may have placeholders for other elements in the
          # diff, so we must fix these before saving the element.
          new.fix_placeholders!(ids, placeholder_id)

          # create element given user
          new.create_with_history(@changeset.user)

          # save placeholder => allocated ID map
          ids[model_sym][placeholder_id] = new.id

          # add the result to the document we're building for return.
          xml_result = XML::Node.new model.to_s.downcase
          xml_result["old_id"] = placeholder_id.to_s
          xml_result["new_id"] = new.id.to_s
          xml_result["new_version"] = new.version.to_s
          result.root << xml_result
        end

      elsif action_name == "modify"
        # modify an existing element. again, this code doesn't directly deal
        # with types, but uses duck typing to handle them transparently.
        with_model do |model, xml|
          # get the new element from the XML payload
          new = model.from_xml_node(xml, false)
          check(model, xml, new)

          # if the ID is a placeholder then map it to the real ID
          model_sym = model.to_s.downcase.to_sym
          client_id = new.id
          is_placeholder = ids[model_sym].include? client_id
          id = is_placeholder ? ids[model_sym][client_id] : client_id

          # and the old one from the database
          old = model.find(id)

          # translate any placeholder IDs to their true IDs.
          new.fix_placeholders!(ids)
          new.id = id

          old.update_from(new, @changeset.user)

          xml_result = XML::Node.new model.to_s.downcase
          xml_result["old_id"] = client_id.to_s
          xml_result["new_id"] = id.to_s
          # version is updated in "old" through the update, so we must not
          # return new.version here but old.version!
          xml_result["new_version"] = old.version.to_s
          result.root << xml_result
        end

      elsif action_name == "delete"
        # delete action. this takes a payload in API 0.6, so we need to do
        # most of the same checks that are done for the modify.
        with_model do |model, xml|
          # delete doesn't have to contain a full payload, according to
          # the wiki docs, so we just extract the things we need.
          new_id = xml["id"].to_i
          raise OSM::APIBadXMLError.new(model, xml, "ID attribute is required") if new_id.nil?

          # if the ID is a placeholder then map it to the real ID
          model_sym = model.to_s.downcase.to_sym
          is_placeholder = ids[model_sym].include? new_id
          id = is_placeholder ? ids[model_sym][new_id] : new_id

          # build the "new" element by modifying the existing one
          new = model.find(id)
          new.changeset_id = xml["changeset"].to_i
          new.version = xml["version"].to_i
          check(model, xml, new)

          # fetch the matching old element from the DB
          old = model.find(id)

          # can a delete have placeholders under any circumstances?
          # if a way is modified, then deleted is that a valid diff?
          new.fix_placeholders!(ids)

          xml_result = XML::Node.new model.to_s.downcase
          # oh, the irony... the "new" element actually contains the "old" ID
          # a better name would have been client/server, but anyway...
          xml_result["old_id"] = new_id.to_s

          if action_attributes["if-unused"]
            begin
              old.delete_with_history!(new, @changeset.user)
            rescue OSM::APIAlreadyDeletedError, OSM::APIPreconditionFailedError
              xml_result["new_id"] = old.id.to_s
              xml_result["new_version"] = old.version.to_s
            end
          else
            old.delete_with_history!(new, @changeset.user)
          end

          result.root << xml_result
        end

      else
        # no other actions to choose from, so it must be the users fault!
        raise OSM::APIChangesetActionInvalid.new(action_name)
      end
    end

    # return the XML document to be rendered back to the client
    result
  end
end
