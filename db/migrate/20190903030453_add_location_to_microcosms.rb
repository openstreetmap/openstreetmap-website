class AddLocationToMicrocosms < ActiveRecord::Migration[5.2]
  def change
    add_column 'microcosms', 'location', 'string', null: false
    add_column 'microcosms', 'lat', 'decimal', null: false
    add_column 'microcosms', 'lon', 'decimal', null: false
    add_column 'microcosms', 'min_lat', 'integer', null: false
    add_column 'microcosms', 'max_lat', 'integer', null: false
    add_column 'microcosms', 'min_lon', 'integer', null: false
    add_column 'microcosms', 'max_lon', 'integer', null: false
  end
end
