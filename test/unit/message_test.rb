require File.dirname(__FILE__) + '/../test_helper'

class MessageTest < Test::Unit::TestCase
  fixtures :messages, :users

  # This needs to be updated when new fixtures are added
  # or removed.
  def test_check_message_count
    assert_equal 2, Message.count
  end

  def test_check_empty_message_fails
    message = Message.new
    assert !message.valid?
    assert message.errors.invalid?(:title)
    assert message.errors.invalid?(:body)
    assert message.errors.invalid?(:sent_on)
    assert true, message.message_read
  end
  
  def test_validating_msgs
    message = messages(:one)
    assert_equal true, message.valid?
    massage = messages(:two)
    assert_equal true, message.valid?
  end
  
end
