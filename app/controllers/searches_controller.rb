# frozen_string_literal: true

class SearchesController < ApplicationController
  include NominatimMethods

  before_action :authorize_web
  before_action :set_locale
  before_action :require_oauth

  authorize_resource :class => false

  before_action :normalize_params

  def show
    @sources = []

    if params[:lat] && params[:lon]
      @sources.push(:name => "latlon", :url => root_path,
                    :fetch_url => search_latlon_query_path(params.permit(:lat, :lon, :latlon_digits, :zoom)))
      @sources.push(:name => "nominatim_reverse", :url => nominatim_reverse_query_url(:format => "html"),
                    :fetch_url => search_nominatim_reverse_query_path(params.permit(:lat, :lon, :zoom)))
    elsif params[:query]
      @sources.push(:name => "nominatim", :url => nominatim_query_url(:format => "html"),
                    :fetch_url => search_nominatim_query_path(params.permit(:query, :minlat, :minlon, :maxlat, :maxlon)))
    end

    if @sources.empty?
      head :bad_request
    else
      render :layout => map_layout
    end
  end

  private

  def normalize_params
    if (query = params[:query])
      query.strip!

      if (latlon = query.match(/^(?<ns>[NS])\s*#{dms_regexp('ns')}\W*(?<ew>[EW])\s*#{dms_regexp('ew')}$/) ||
                   query.match(/^#{dms_regexp('ns')}\s*(?<ns>[NS])\W*#{dms_regexp('ew')}\s*(?<ew>[EW])$/))
        params.merge!(to_decdeg(latlon.named_captures.compact)).delete(:query)

      elsif (latlon = query.match(%r{^(?<lat>[+-]?\d+(?:\.\d+)?)(?:\s+|\s*[,/]\s*)(?<lon>[+-]?\d+(?:\.\d+)?)$}))
        params.merge!(latlon.named_captures).delete(:query)

        params[:latlon_digits] = true
      end
    end
  end

  def dms_regexp(name_prefix)
    /
      (?: (?<#{name_prefix}d>\d{1,3}(?:\.\d+)?)°? ) |
      (?: (?<#{name_prefix}d>\d{1,3})°?\s*(?<#{name_prefix}m>\d{1,2}(?:\.\d+)?)['′]? ) |
      (?: (?<#{name_prefix}d>\d{1,3})°?\s*(?<#{name_prefix}m>\d{1,2})['′]?\s*(?<#{name_prefix}s>\d{1,2}(?:\.\d+)?)["″]? )
    /x
  end

  def to_decdeg(captures)
    ns = captures.fetch("ns").casecmp?("s") ? -1 : 1
    nsd = BigDecimal(captures.fetch("nsd", "0"))
    nsm = BigDecimal(captures.fetch("nsm", "0"))
    nss = BigDecimal(captures.fetch("nss", "0"))

    ew = captures.fetch("ew").casecmp?("w") ? -1 : 1
    ewd = BigDecimal(captures.fetch("ewd", "0"))
    ewm = BigDecimal(captures.fetch("ewm", "0"))
    ews = BigDecimal(captures.fetch("ews", "0"))

    lat = ns * (nsd + (nsm / 60) + (nss / 3600))
    lon = ew * (ewd + (ewm / 60) + (ews / 3600))

    { :lat => lat.round(6).to_s("F"), :lon => lon.round(6).to_s("F") }
  end
end
