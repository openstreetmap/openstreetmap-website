require File.dirname(__FILE__) + '/../test_helper'

class MessageTest < Test::Unit::TestCase
  fixtures :messages, :users

  def test_check_empty_message_fails
    message = Message.new
    assert !message.valid?
    assert message.errors.invalid?(:title)
    assert message.errors.invalid?(:body)
    assert message.errors.invalid?(:sent_on)
    assert true, message.message_read
  end
  
end
