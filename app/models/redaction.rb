# == Schema Information
#
# Table name: redactions
#
#  id                 :integer          not null, primary key
#  title              :string
#  description        :text
#  created_at         :datetime
#  updated_at         :datetime
#  user_id            :bigint(8)        not null
#  description_format :enum             default("markdown"), not null
#
# Foreign Keys
#
#  redactions_user_id_fkey  (user_id => users.id)
#

##
# Redaction represents a record associated with a particular
# action on the database to hide revisions from the history
# which are not appropriate to redistribute any more.
#
# The circumstances of the redaction can be recorded in the
# record's title and description fields, which can be
# displayed linked from the redacted records.
#
class Redaction < ActiveRecord::Base
  belongs_to :user

  has_many :old_nodes
  has_many :old_ways
  has_many :old_relations

  validates :title, :description, :invalid_chars => true
  validates :description, :presence => true
  validates :description_format, :inclusion => { :in => %w[text html markdown] }

  # this method overrides the AR default to provide the rich
  # text object for the description field.
  def description
    RichText.new(self[:description_format], self[:description])
  end
end
