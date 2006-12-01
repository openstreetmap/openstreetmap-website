class CreateTracepoints < ActiveRecord::Migration
  def self.up
    create_table :tracepoints do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :tracepoints
  end
end
