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
  has_many :nodes
  has_many :ways
  has_many :relations
end
