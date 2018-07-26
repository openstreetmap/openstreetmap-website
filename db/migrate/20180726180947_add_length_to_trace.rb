class AddLengthToTrace < ActiveRecord::Migration[5.2]
  def up
    add_column "gpx_files", "length", :bigint
  end

  def down
    remove_column "gpx_files", "length"
  end
end
