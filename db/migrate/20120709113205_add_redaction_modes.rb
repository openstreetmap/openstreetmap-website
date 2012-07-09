class AddRedactionModes < ActiveRecord::Migration
  def up
    [:nodes, :ways, :relations].each do |tbl|
      add_column tbl, :redaction_mode, :string, :null => true
    end
  end

  def down
    [:nodes, :ways, :relations].each do |tbl|
      remove_column tbl, :redaction_mode
    end
  end
end
