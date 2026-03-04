# frozen_string_literal: true

module AssetHelper
  def assets(directory)
    if (manifest = Rails.application.assets_manifest.assets) && !manifest.empty?
      # With precompiled assets
      manifest.keys.each_with_object({}) do |asset, assets|
        assets[asset] = asset_path(asset) if asset.start_with?("#{directory}/")
      end
    elsif (env = Rails.application.assets) && env.present?
      # Without precompiled assets
      env.paths
         .filter { |path| path.include?(directory) }
         .flat_map { |path| Dir.glob(File.join(path, "**", "*")) }
         .filter_map { |path| env.find_asset(path) }
         .each_with_object({}) do |asset, assets|
           assets[asset.logical_path] = asset_path(asset.logical_path) if asset.logical_path.start_with?("#{directory}/")
         end
    end
  end
end
