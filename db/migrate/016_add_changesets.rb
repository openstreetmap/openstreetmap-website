class AddChangesets < ActiveRecord::Migration
  def self.up
    create_table "changesets", innodb_table do |t|
      t.column "id",             :bigint,   :limit => 20, :null => false
      t.column "user_id",        :bigint,   :limit => 20, :null => false
      t.column "created_at",     :datetime,               :null => false
      t.column "open",           :boolean,                :null => false, :default => true
      t.column "min_lat",        :integer,                :null => true
      t.column "max_lat",        :integer,                :null => true
      t.column "min_lon",        :integer,                :null => true
      t.column "max_lon",        :integer,                :null => true
    end

    add_primary_key "changesets", ["id"]
    # FIXME add indexes?

    change_column "changesets", "id", :bigint, :limit => 20, :null => false, :options => "AUTO_INCREMENT"

    create_table "changeset_tags", innodb_table do |t|
      t.column "id", :bigint, :limit => 64, :null => false
      t.column "k",  :string, :default => "", :null => false
      t.column "v",  :string, :default => "", :null => false
    end

    add_index "changeset_tags", ["id"], :name => "changeset_tags_id_idx"
  end

  def self.down
    drop_table "changesets"
    drop_table "changeset_tags"
  end
end
