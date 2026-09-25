# frozen_string_literal: true

module AssetHelper
  def assets(directory)
    asset_list = Rails.application.assets_manifest.assets.keys
    if asset_list.empty?
      # when assets are not precompiled
      env = Rails.application.assets
      env.each_file do |path|
        asset_list << env[path]&.logical_path if path.include?(directory)
      end
    end
    asset_list.each_with_object({}) do |asset, assets|
      assets[asset] = asset_path(asset) if asset&.start_with?("#{directory}/")
    end
  end
end
