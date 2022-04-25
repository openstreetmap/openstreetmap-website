module AssetHelper
  def assets(directory)
    Rails.application.assets_manifest.assets.keys.each_with_object({}) do |asset, assets|
      assets[asset] = asset_path(asset) if asset.start_with?("#{directory}/")
    end
  end
end
