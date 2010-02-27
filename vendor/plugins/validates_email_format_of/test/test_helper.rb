$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'active_record'
require 'active_record/base'

require 'validates_email_format_of'

ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => ':memory:')

ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.column 'email', :string
  end
end

class Person < ActiveRecord::Base
  validates_email_format_of :email, :on => :create, :message => 'fails with custom message', :allow_nil => true
end

require 'test/unit'
require 'shoulda'
require "#{File.dirname(__FILE__)}/../init"

class Test::Unit::TestCase #:nodoc:
  def self.should_allow_values(klass,*good_values)
    good_values.each do |v|
      should "allow email to be set to #{v.inspect}" do
        user = klass.new(:email => v)
        user.save
        assert_nil user.errors.on(:email)
      end
    end
  end

  def self.should_not_allow_values(klass,*bad_values)
    bad_values.each do |v|
      should "not allow email to be set to #{v.inspect}" do
        user = klass.new(:email => v)
        assert !user.save, "Saved user with email set to \"#{v}\""
        assert user.errors.on(:email), "There are no errors set on email after being set to \"#{v}\""
      end
    end
  end
end
