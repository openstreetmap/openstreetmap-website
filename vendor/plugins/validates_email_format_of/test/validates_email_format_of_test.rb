require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../shoulda_macros/validates_email_format_of'

class User < ActiveRecord::Base
  validates_email_format_of :email,
    :on        => :create,
    :message   => 'fails with custom message',
    :allow_nil => true
end

class ValidatesEmailFormatOfTest < Test::Unit::TestCase
  should_validate_email_format_of_klass(User, :email)

  context 'An invalid user on update' do
    setup do
      @user = User.new(:email => 'dcroak@thoughtbot.com')
      assert @user.save
      assert @user.update_attribute(:email, '..dcroak@thoughtbot.com')
    end

    should 'pass validation' do
      assert @user.valid?
      assert @user.save
      assert_nil @user.errors.on(:email)
    end
  end

  context 'A user with a nil email' do
    setup { @user = User.new(:email => nil) }

    should 'pass validation' do
      assert @user.valid?
      assert @user.save
      assert_nil @user.errors.on(:email)
    end
  end
end
