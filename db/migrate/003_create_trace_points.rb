class CreateTracePoints < ActiveRecord::Migration
  def self.up
    create_table :trace_points do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :trace_points
  end
end
