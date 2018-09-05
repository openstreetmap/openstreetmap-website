atom_feed(:language => I18n.locale, :schema_date => 2009,
          :id => url_for(@params.merge(:only_path => false)),
          :root_url => url_for(@params.merge(:action => :list, :format => nil, :only_path => false)),
          "xmlns:georss" => "http://www.georss.org/georss") do |feed|
  feed.title changeset_list_title(params, current_user)

  feed.updated @edits.map { |e| [e.created_at, e.closed_at].max }.max
  feed.icon image_url("favicon.ico")
  feed.logo image_url("mag_map-rss2.0.png")

  feed.rights :type => "xhtml" do |xhtml|
    xhtml.a :href => "https://creativecommons.org/licenses/by-sa/2.0/" do |a|
      a.img :src => image_url("cc_button.png"), :alt => "CC by-sa 2.0"
    end
  end

  @edits.each do |changeset|
    feed.entry(changeset, :updated => changeset.closed_at, :id => changeset_url(changeset.id, :only_path => false)) do |entry|
      entry.link :rel => "alternate",
                 :href => changeset_read_url(changeset, :only_path => false),
                 :type => "application/osm+xml"
      entry.link :rel => "alternate",
                 :href => changeset_download_url(changeset, :only_path => false),
                 :type => "application/osmChange+xml"

      if !changeset.tags.empty? && changeset.tags.key?("comment")
        entry.title t("browse.changeset.feed.title_comment", :id => h(changeset.id), :comment => h(changeset.tags["comment"])), :type => "html"
      else
        entry.title t("browse.changeset.feed.title", :id => h(changeset.id))
      end

      if changeset.user.data_public?
        entry.author do |author|
          author.name changeset.user.display_name
          author.uri user_url(changeset.user, :only_path => false)
        end
      end

      feed.content :type => "xhtml" do |xhtml|
        xhtml.style "th { text-align: left } tr { vertical-align: top }"
        xhtml.table do |table|
          table.tr do |tr|
            tr.th t("browse.created")
            tr.td l(changeset.created_at)
          end
          table.tr do |tr|
            tr.th t("browse.closed")
            tr.td l(changeset.closed_at)
          end
          if changeset.user.data_public?
            table.tr do |tr|
              tr.th t("browse.changeset.belongs_to")
              tr.td do |td|
                td.a h(changeset.user.display_name), :href => user_url(changeset.user, :only_path => false)
              end
            end
          end
          unless changeset.tags.empty?
            table.tr do |tr|
              tr.th t("browse.tag_details.tags")
              tr.td do |td|
                td.table :cellpadding => "0" do |table|
                  changeset.tags.sort.each do |tag|
                    table.tr do |tr|
                      tr.td << "#{h(tag[0])} = #{linkify(h(tag[1]))}"
                    end
                  end
                end
              end
            end
          end
        end
      end

      if changeset.has_valid_bbox?
        bbox = changeset.bbox.to_unscaled

        # See http://georss.org/Encodings#Geometry
        lower_corner = "#{bbox.min_lat} #{bbox.min_lon}"
        upper_corner = "#{bbox.max_lat} #{bbox.max_lon}"

        feed.georss :box, lower_corner + " " + upper_corner
      end
    end
  end
end
