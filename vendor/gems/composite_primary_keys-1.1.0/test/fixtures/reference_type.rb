class ReferenceType < ActiveRecord::Base
  set_primary_key :reference_type_id
  has_many :reference_codes, :foreign_key => "reference_type_id"
  
  validates_presence_of :type_label, :abbreviation
  validates_uniqueness_of :type_label
end
