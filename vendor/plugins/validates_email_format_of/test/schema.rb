ActiveRecord::Schema.define(:version => 0) do
  create_table :people, :force => true do |t|
    t.column "email", :string
  end

  create_table :mx_records, :force => true do |t|
    t.column "email", :string
  end

end