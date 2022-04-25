class AddUserTouAgreed < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :tou_agreed, :datetime
  end
end
