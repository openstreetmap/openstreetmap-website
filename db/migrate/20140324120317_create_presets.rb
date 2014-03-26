class CreatePresets < ActiveRecord::Migration
  def change
    create_table :presets do |t|
      t.text :json

      t.timestamps
    end
  end
end
