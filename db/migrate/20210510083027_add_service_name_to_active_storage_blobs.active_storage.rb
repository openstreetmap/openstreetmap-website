# This migration comes from active_storage (originally 20190112182829)
class AddServiceNameToActiveStorageBlobs < ActiveRecord::Migration[6.0]
  def up
    unless column_exists?(:active_storage_blobs, :service_name)
      add_column :active_storage_blobs, :service_name, :string, :null => false, :default => ActiveStorage::Blob.service.name
      change_column :active_storage_blobs, :service_name, :string, :null => false, :default => nil
    end
  end

  def down
    remove_column :active_storage_blobs, :service_name
  end
end
