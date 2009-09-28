class UserRole < ActiveRecord::Base

  ALL_ROLES = ['administrator', 'moderator']

  validates_inclusion_of :role, :in => ALL_ROLES
  belongs_to :user

end
