class User < ActiveRecord::Base
  has_many :traces
end
