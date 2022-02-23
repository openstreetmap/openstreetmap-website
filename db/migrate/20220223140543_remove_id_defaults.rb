class RemoveIdDefaults < ActiveRecord::Migration[7.0]
  def change
    # Remove defaults from foreign key references
    change_column_default :gpx_file_tags, :gpx_id, :from => 0, :to => nil
    change_column_default :relation_members, :relation_id, :from => 0, :to => nil
    change_column_default :relation_tags, :relation_id, :from => 0, :to => nil
    change_column_default :way_tags, :way_id, :from => 0, :to => nil

    # Remove defaults from primary keys
    change_column_default :relations, :relation_id, :from => 0, :to => nil
    change_column_default :ways, :way_id, :from => 0, :to => nil
  end
end
