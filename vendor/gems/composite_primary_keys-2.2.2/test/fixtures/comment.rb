class Comment < ActiveRecord::Base
  set_primary_keys :id
  belongs_to :person, :polymorphic => true
  belongs_to :hack
end

