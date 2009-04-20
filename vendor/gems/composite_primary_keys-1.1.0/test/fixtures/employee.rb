class Employee < ActiveRecord::Base
	belongs_to :department, :foreign_key => [:department_id, :location_id]
	has_many :comments, :as => :person
end
