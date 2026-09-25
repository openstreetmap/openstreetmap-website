# frozen_string_literal: true

module Api
  module ElementsTestHelper
    private

    def affected_models
      []
    end

    def with_unchanging_request(*, &)
      with_request(*) do |headers, changeset|
        assert_no_difference(affected_models.map { |model| -> { model.count } }) do
          yield headers, changeset
        end

        if changeset
          changeset.reload
          assert_equal 0, changeset.num_changes
          assert_predicate changeset, :num_type_changes_in_sync?
        end
      end
    end

    def with_request(user_options = [], changeset_options = [], &)
      user = create_user_for_request(user_options)
      changeset = create_changeset_for_request(changeset_options, user)

      yield bearer_authorization_header(user), changeset
    end

    def create_user_for_request(options)
      factories = [:user, :importer_user, :moderator_user, :administrator_user, :super_user]
      options = [:user, *options] unless factories.include? options[0]

      create(*options)
    end

    def create_changeset_for_request(options, user)
      options = [:changeset, *options] unless options[0] == :changeset

      if options in [*positional, { **keywords }]
        keywords = { :user => user }.merge(keywords)
        create(*positional, **keywords)
      else
        create(*options, :user => user)
      end
    end

    def with_unchanging(*, &)
      element = create(*)
      element_version = element.version
      element_visible = element.visible

      yield element

      element.reload
      assert_equal element_version, element.version, "element version changed"
      assert_equal element_visible, element.visible, "element visibility changed"
    end

    ##
    # update the changeset_id of a node element
    def update_changeset(xml, changeset_id)
      xml_attr_rewrite(xml, "changeset", changeset_id)
    end
  end
end
