module QueryMethods
  extend ActiveSupport::Concern

  private

  ##
  # Restrict the resulting items to those created during a particular time period
  # Using 'to' requires specifying 'from' as well for historical reasons
  def query_conditions_time(items, filter_property = :created_at)
    interval = query_conditions_time_value

    if interval
      items.where(filter_property => interval)
    else
      items
    end
  end

  ##
  # Get query time interval from request parameters or nil
  def query_conditions_time_value
    if params[:from]
      begin
        from = Time.parse(params[:from]).utc
      rescue ArgumentError
        raise OSM::APIBadUserInput, "Date #{params[:from]} is in a wrong format"
      end

      begin
        to = if params[:to]
               Time.parse(params[:to]).utc
             else
               Time.now.utc
             end
      rescue ArgumentError
        raise OSM::APIBadUserInput, "Date #{params[:to]} is in a wrong format"
      end

      from..to
    end
  end

  ##
  # Limit the result according to request parameters and settings
  def query_limit(items)
    items.limit(query_limit_value)
  end

  ##
  # Get query limit value from request parameters and settings
  def query_limit_value
    name = controller_path.sub(%r{^api/}, "").tr("/", "_").singularize
    max_limit = Settings["max_#{name}_query_limit"]
    default_limit = Settings["default_#{name}_query_limit"]
    if params[:limit]
      if params[:limit].to_i.positive? && params[:limit].to_i <= max_limit
        params[:limit].to_i
      else
        raise OSM::APIBadUserInput, "#{controller_name.classify} limit must be between 1 and #{max_limit}"
      end
    else
      default_limit
    end
  end
end
