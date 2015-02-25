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

  # this method overrides the AR default to provide the rich
  # text object for the description field.
  def description
    RichText.new(self[:description_format], self[:description])
  end
end
