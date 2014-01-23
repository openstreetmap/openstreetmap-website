class Group < ActiveRecord::Base
  has_many :group_memberships, :dependent => :destroy
  has_many :users, :through => :group_memberships
  has_many :leaders, 
           :class_name => 'User', 
           :source => :user, 
           :through => :group_memberships, 
           :conditions => {
             :group_memberships => {
                :role => GroupMembership::Roles::LEADER
             }
           }

  accepts_nested_attributes_for :group_memberships, :allow_destroy => true

  validates :title, :length => { :in => 3..250 }
  validates :description, :length => { :in => 2..1000 }

  after_initialize :set_defaults

  def leadership_includes?(user)
    group_memberships.where(:role => GroupMembership::Roles::LEADER, :user_id => user.id).count > 0
  end

  def description
    RichText.new(read_attribute(:description_format), read_attribute(:description))
  end

private
  def set_defaults
    self.description_format = "markdown" unless self.attribute_present?(:description_format)
  end
end
