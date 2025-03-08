module Api
  module Changesets
    class DownloadsController < ApiController
      before_action :setup_user_auth

      authorize_resource :changeset

      before_action :set_request_formats

      ##
      # download the changeset as an osmChange document.
      #
      # to make it easier to revert diffs it would be better if the osmChange
      # format were reversible, i.e: contained both old and new versions of
      # modified elements. but it doesn't at the moment...
      #
      # this method cannot order the database changes fully (i.e: timestamp and
      # version number may be too coarse) so the resulting diff may not apply
      # to a different database. however since changesets are not atomic this
      # behaviour cannot be guaranteed anyway and is the result of a design
      # choice.
      def show
        changeset = Changeset.find(params[:changeset_id])

        # get all the elements in the changeset which haven't been redacted
        # and stick them in a big array.
        elements = if show_redactions?
                     [changeset.old_nodes,
                      changeset.old_ways,
                      changeset.old_relations].flatten
                   else
                     [changeset.old_nodes.unredacted,
                      changeset.old_ways.unredacted,
                      changeset.old_relations.unredacted].flatten
                   end

        # sort the elements by timestamp and version number, as this is the
        # almost sensible ordering available. this would be much nicer if
        # global (SVN-style) versioning were used - then that would be
        # unambiguous.
        elements.sort_by! { |e| [e.timestamp, e.version] }

        # generate an output element for each operation. note: we avoid looking
        # at the history because it is simpler - but it would be more correct to
        # check these assertions.
        @created = []
        @modified = []
        @deleted = []

        elements.each do |elt|
          if elt.version == 1
            # first version, so it must be newly-created.
            @created << elt
          elsif elt.visible
            # must be a modify
            @modified << elt
          else
            # if the element isn't visible then it must have been deleted
            @deleted << elt
          end
        end

        respond_to do |format|
          format.xml
        end
      end

      private

      def show_redactions?
        current_user&.moderator? && params[:show_redactions] == "true"
      end
    end
  end
end
