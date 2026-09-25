# frozen_string_literal: true

class AddCompanyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :company, :string
  end
end
