class AddShowContributionHeatmapToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :show_contribution_heatmap, :boolean, :default => true, :null => false
  end
end
