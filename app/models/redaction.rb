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

  after_initialize :set_defaults

  # this method overrides the AR default to provide the rich 
  # text object for the description field.
  def description
    RichText.new(read_attribute(:description_format), read_attribute(:description))
  end

  private

  # set the default format to be markdown, in the absence of
  # any other setting.
  def set_defaults
    self.description_format = "markdown" unless self.attribute_present?(:description_format)
  end
end
