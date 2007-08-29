class AddRelations < ActiveRecord::Migration
  def self.up
    # a relation can have members much like a way can have nodes.
    # differences:
    # way: only nodes / relation: any kind of member
    # way: ordered sequence of nodes / relation: free-form "role" string
    create_table "current_relation_members", innodb_table do |t|
      t.column "id",          :bigint, :limit => 64
      t.column "member_type", :string, :limit => 11
      t.column "member_id",   :bigint, :limit => 11
      t.column "member_role", :string
    end
    # enums work like strings but are more efficient
    execute "alter table current_relation_members change column member_type member_type enum('node','way','relation');"

    add_index "current_relation_members", ["member_type", "member_id"], :name => "current_relation_members_member_idx"
    add_index "current_relation_members", ["id"], :name => "current_relation_members_id_idx"

    create_table "current_relation_tags", myisam_table do |t|
      t.column "id", :bigint, :limit => 64
      t.column "k",  :string,                :default => "", :null => false
      t.column "v",  :string,                :default => "", :null => false
    end

    add_index "current_relation_tags", ["id"], :name => "current_relation_tags_id_idx"
    execute "CREATE FULLTEXT INDEX `current_relation_tags_v_idx` ON `current_relation_tags` (`v`)"

    create_table "current_relations", myisam_table do |t|
      t.column "id",        :bigint,   :limit => 64, :null => false
      t.column "user_id",   :bigint,   :limit => 20
      t.column "timestamp", :datetime
      t.column "visible",   :boolean
    end

    add_primary_key "current_relations", ["id"]

    change_column "current_relations", "id", :bigint, :limit => 64, :null => false, :options => "AUTO_INCREMENT"

    create_table "relation_members", myisam_table do |t|
      t.column "id",          :bigint,  :limit => 64, :default => 0, :null => false
      t.column "member_type", :string, :limit => 11
      t.column "member_id",   :bigint, :limit => 11
      t.column "member_role", :string
      t.column "version",     :bigint,  :limit => 20, :default => 0, :null => false
    end

    add_primary_key "relation_members", ["id", "version", "member_id", "member_role"]
    execute "alter table relation_members change column member_type member_type enum('node','way','relation');" 

    create_table "relation_tags", myisam_table do |t|
      t.column "id",      :bigint,  :limit => 64, :default => 0, :null => false
      t.column "k",       :string
      t.column "v",       :string
      t.column "version", :bigint,  :limit => 20
    end

    add_index "relation_tags", ["id", "version"], :name => "relation_tags_id_version_idx"

    create_table "relations", myisam_table do |t|
      t.column "id",        :bigint,   :limit => 64, :default => 0, :null => false
      t.column "user_id",   :bigint,   :limit => 20
      t.column "timestamp", :datetime
      t.column "version",   :bigint,   :limit => 20,                   :null => false
      t.column "visible",   :boolean,                :default => true
    end

    add_primary_key "relations", ["id", "version"]
    add_index "relations", ["id"], :name => "relations_id_version_idx"

    change_column "relations", "version", :bigint, :limit => 20, :null => false, :options => "AUTO_INCREMENT"
  end


  def self.down
    drop_table :relations
    drop_table :current_relations
    drop_table :relation_tags
    drop_table :current_relation_tags
    drop_table :relation_members
    drop_table :current_relation_members
  end
end
