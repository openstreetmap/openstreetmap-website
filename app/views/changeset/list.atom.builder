atom_feed(:language => I18n.locale, :schema_date => 2009,
          :id => url_for(params.merge({ :only_path => false })),
          :root_url => url_for(params.merge({ :only_path => false, :format => nil })),
          "xmlns:georss" => "http://www.georss.org/georss") do |feed|
  feed.title @title

  feed.subtitle :type => 'xhtml' do |xhtml|
    xhtml.p @description
  end

  feed.updated @edits.map {|e|  [e.created_at, e.closed_at].max }.max
  feed.icon "http://#{SERVER_URL}/favicon.ico"
  feed.logo "http://#{SERVER_URL}/images/mag_map-rss2.0.png"

  feed.rights :type => 'xhtml' do |xhtml|
    xhtml.a :href => "http://creativecommons.org/licenses/by-sa/2.0/" do |a|
      a.img :src => "http://#{SERVER_URL}/images/cc_button.png", :alt => "CC by-sa 2.0"
    end
  end

  for changeset in @edits
    feed.entry(changeset, :updated => changeset.closed_at, :id => changeset_url(changeset.id, :only_path => false)) do |entry|
      entry.link :rel => "alternate",
                 :href => changeset_read_url(changeset, :only_path => false),
                 :type => "application/osm+xml"
      entry.link :rel => "alternate",
                 :href => changeset_download_url(changeset, :only_path => false),
                 :type => "application/osmChange+xml"

      entry.title t('browse.changeset.title') + " " + h(changeset.id)

      if changeset.user.data_public?
        entry.author do |author|
          author.name changeset.user.display_name
          author.uri url_for(:controller => 'user', :action => 'view', :display_name => changeset.user.display_name, :only_path => false)
        end
      end

      if changeset.tags['comment']
        feed.content changeset.tags['comment']
      end

      unless changeset.min_lat.nil?
        minlon = changeset.min_lon/GeoRecord::SCALE.to_f
        minlat = changeset.min_lat/GeoRecord::SCALE.to_f
        maxlon = changeset.max_lon/GeoRecord::SCALE.to_f
        maxlat = changeset.max_lat/GeoRecord::SCALE.to_f

        # See http://georss.org/Encodings#Geometry
        lower_corner = "#{minlat} #{minlon}"
        upper_corner = "#{maxlat} #{maxlon}"

        feed.georss :box, lower_corner + " " + upper_corner
      end
    end
  end
end
