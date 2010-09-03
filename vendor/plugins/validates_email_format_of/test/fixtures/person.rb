class Person < ActiveRecord::Base
  validates_email_format_of :email, 
                            :on => :create, 
                            :message => 'fails with custom message', 
                            :allow_nil => true
end

class MxRecord < ActiveRecord::Base
  validates_email_format_of :email, 
                            :on => :create, 
                            :check_mx => true
end
