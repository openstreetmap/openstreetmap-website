# frozen_string_literal: true

atom_feed(:language => I18n.locale, :schema_date => 2009,
          :id => url_for(@params.merge(:only_path => false)),
          :root_url => url_for(@params.merge(:action => :index, :format => nil, :only_path => false)),
          "xmlns:xhtml" => "http://www.w3.org/1999/xhtml",
          "xmlns:georss" => "http://www.georss.org/georss") do |feed|
  feed.title changeset_index_title(params, @user)

  feed.updated @changesets.map { |e| [e.created_at, e.closed_at].max }.max
  feed.icon image_url("favicon.ico")
  feed.logo image_url("mag_map-rss2.0.png")

  feed.rights :type => "xhtml" do |xhtml|
    xhtml.a "Open Data Commons Open Database License", :href => "https://opendatacommons.org/licenses/odbl/"
  end

  @changesets.each do |changeset|
    feed.entry(changeset, :updated => changeset.closed_at, :id => changeset_url(changeset.id, :only_path => false)) do |entry|
      entry.link :rel => "alternate",
                 :href => api_changeset_url(changeset, :only_path => false),
                 :type => "application/osm+xml"
      entry.link :rel => "alternate",
                 :href => api_changeset_download_url(changeset, :only_path => false),
                 :type => "application/osmChange+xml"

      if !changeset.tags.empty? && changeset.tags.key?("comment")
        entry.title t(".feed.title_comment", :id => changeset.id, :comment => changeset.tags["comment"])
      else
        entry.title t(".feed.title", :id => changeset.id)
      end

      if changeset.user.data_public? && changeset.user.status != "deleted"
        entry.author do |author|
          author.name changeset.user.display_name
          author.uri user_url(changeset.user, :only_path => false)
        end
      end

      feed.content :type => "xhtml" do |xhtml|
        xhtml.style "th { text-align: left } tr { vertical-align: top }"
        xhtml.table do |table|
          table.tr do |tr|
            tr.th t(".feed.created")
            tr.td l(changeset.created_at)
          end
          table.tr do |tr|
            tr.th t(".feed.closed")
            tr.td l(changeset.closed_at)
          end
          if changeset.user.data_public? && changeset.user.status != "deleted"
            table.tr do |tr|
              tr.th t(".feed.belongs_to")
              tr.td do |td|
                td.a changeset.user.display_name, :href => user_url(changeset.user, :only_path => false)
              end
            end
          end
          unless changeset.tags.empty?
            table.tr do |tr|
              tr.th t("browse.tag_details.tags")
              tr.td do |td|
                td.table :cellpadding => "0" do |tag_table|
                  changeset.tags.sort.each do |tag|
                    tag_table.tr do |tag_tr|
                      tag_tr.td "#{tag[0]} = #{linkify(tag[1])}"
                    end
                  end
                end
              end
            end
          end
        end
      end

      if changeset.bbox_valid?
        bbox = changeset.bbox.to_unscaled

        # See http://georss.org/Encodings#Geometry
        lower_corner = "#{bbox.min_lat} #{bbox.min_lon}"
        upper_corner = "#{bbox.max_lat} #{bbox.max_lon}"

        feed.georss :box, "#{lower_corner} #{upper_corner}"
      end
    end
  end
end
