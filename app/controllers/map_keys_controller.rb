class MapKeysController < ApplicationController
  before_action :authorize_web
  before_action :set_locale
  authorize_resource :class => false

  def show
    expires_in 7.days, :public => true
    @key = YAML.load_file(Rails.root.join("config/key.yml"))
    @key.each_value do |layer_data|
      layer_data.each do |entry|
        entry["name"] = Array(entry["name"])
      end
      layer_data.each_cons(2) do |entry, next_entry|
        entry["max_zoom"] = next_entry["min_zoom"] - 1 if entry["name"] == next_entry["name"] && !entry["max_zoom"] && next_entry["min_zoom"]
      end
    end
    render :layout => false
  end
end
