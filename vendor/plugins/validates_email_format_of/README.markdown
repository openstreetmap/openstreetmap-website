Validates email format
======================

Validate various formats of email address against RFC 2822.

Usage
-----
  
    class PersonTest < ActiveSupport::TestCase
      should_validate_email_format_of :email
    end

    class Person < ActiveRecord::Base
      validates_email_format_of :email
    end

Options
-------

    :message =>
      String. A custom error message (default is: " does not appear to be a valid e-mail address")

    :on =>
      Symbol. Specifies when this validation is active (default is :save, other options :create, :update)

    :allow_nil =>
      Boolean. Allow nil values (default is false)

    :allow_blank =>
      Boolean. Allow blank values (default is false)

    :if =>
      Specifies a method, proc or string to call to determine if the validation should occur 
      (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }). The method, 
      proc or string should return or evaluate to a true or false value. 

    :unless =>
      See :if option.

Testing
-------

To execute the unit tests run <tt>rake test</tt>.

The unit tests for this plugin use an in-memory sqlite3 database.

Installing the gem
------------------

* gem sources -a http://gems.github.com (only needed once)
* sudo gem install dancroak-validates\_email\_format\_of

Credits
-------

Written by Alex Dunae (dunae.ca), 2006-07.

Thanks to Francis Hwang (http://fhwang.net/) at Diversion Media for creating the 1.1 update.
