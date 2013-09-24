module AssetHelper
  def assets(directory)
    assets = {}

    Rails.application.assets.index.each_logical_path("#{directory}/*") do |path|
      assets[path.sub(/^#{directory}\//, "")] = asset_path(path)
    end

    assets
  end
end
