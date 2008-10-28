class <%= migration_name %> < ActiveRecord::Migration

  class Session < ActiveRecord::Base; end

  def self.up
    c = ActiveRecord::Base.connection
    if c.tables.include?('sessions')
      if (columns = Session.column_names).include?('sessid')
        rename_column :sessions, :sessid, :session_id
      else
        add_column :sessions, :session_id, :string unless columns.include?('session_id')
        add_column :sessions, :data, :text unless columns.include?('data')
        if columns.include?('created_on')
          rename_column :sessions, :created_on, :created_at
        else
          add_column :sessions, :created_at, :timestamp unless columns.include?('created_at')
        end
        if columns.include?('updated_on')
          rename_column :sessions, :updated_on, :updated_at
        else
          add_column :sessions, :updated_at, :timestamp unless columns.include?('updated_at')
        end
      end
    else
      create_table :sessions, :options => '<%= database == "mysql" ? "ENGINE=MyISAM" : "" %>' do |t|
        t.column :session_id, :string
        t.column :data,       :text
        t.column :created_at, :timestamp
        t.column :updated_at, :timestamp
      end
      add_index :sessions, :session_id, :name => 'session_id_idx'
    end
  end

  def self.down
    raise IrreversibleMigration
  end
end
