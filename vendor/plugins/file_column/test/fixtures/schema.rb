ActiveRecord::Schema.define do
  create_table :entries, :force => true do |t|
    t.column :image, :string, :null => true
    t.column :file, :string, :null => false
  end
  
  create_table :movies, :force => true do |t|
    t.column :movie, :string
  end
end
