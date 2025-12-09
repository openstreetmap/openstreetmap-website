# frozen_string_literal: true

class AddPublicHeatmapToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :public_heatmap, :boolean, :default => true, :null => false
  end
end
