class Department < ActiveRecord::Base
  # set_primary_keys *keys - turns on composite key functionality
  set_primary_keys :department_id, :location_id
  has_many :employees, :foreign_key => [:department_id, :location_id]
end
