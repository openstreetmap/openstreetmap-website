module QueryMethods
  extend ActiveSupport::Concern

  private

  ##
  # Limit the result according to request parameters and settings
  def query_limit(items)
    items.limit(query_limit_value)
  end

  ##
  # Get query limit value from request parameters and settings
  def query_limit_value
    max_limit = Settings["max_#{controller_name.singularize}_query_limit"]
    default_limit = Settings["default_#{controller_name.singularize}_query_limit"]
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
