# -*- coding: utf-8 -*-
require "test_helper"

class MessageTest < ActiveSupport::TestCase
  api_fixtures
  fixtures :messages

  EURO = "\xe2\x82\xac".freeze # euro symbol

  # This needs to be updated when new fixtures are added
  # or removed.
  def test_check_message_count
    assert_equal 2, Message.count
  end

  def test_check_empty_message_fails
    message = Message.new
    assert !message.valid?
    assert message.errors[:title].any?
    assert message.errors[:body].any?
    assert message.errors[:sent_on].any?
    assert !message.message_read
  end

  def test_validating_msgs
    message = messages(:unread_message)
    assert message.valid?
    message = messages(:read_message)
    assert message.valid?
  end

  def test_invalid_send_recipient
    message = messages(:unread_message)
    message.sender = nil
    message.recipient = nil
    assert !message.valid?

    assert_raise(ActiveRecord::RecordNotFound) { User.find(0) }
    message.from_user_id = 0
    message.to_user_id = 0
    assert_raise(ActiveRecord::RecordInvalid) { message.save! }
  end

  def test_utf8_roundtrip
    (1..255).each do |i|
      assert_message_ok("c", i)
      assert_message_ok(EURO, i)
    end
  end

  def test_length_oversize
    assert_raise(ActiveRecord::RecordInvalid) { make_message("c", 256).save! }
    assert_raise(ActiveRecord::RecordInvalid) { make_message(EURO, 256).save! }
  end

  def test_invalid_utf8
    # See e.g http://en.wikipedia.org/wiki/UTF-8 for byte sequences
    # FIXME: Invalid Unicode characters can still be encoded into "valid" utf-8 byte sequences - maybe check this too?
    invalid_sequences = ["\xC0",         # always invalid utf8
                         "\xC2\x4a",     # 2-byte multibyte identifier, followed by plain ASCII
                         "\xC2\xC2",     # 2-byte multibyte identifier, followed by another one
                         "\x4a\x82",     # plain ASCII, followed by multibyte continuation
                         "\x82\x82",     # multibyte continuations without multibyte identifier
                         "\xe1\x82\x4a"] # three-byte identifier, contination and (incorrectly) plain ASCII
    invalid_sequences.each do |char|
      begin
        # create a message and save to the database
        msg = make_message(char, 1)
        # if the save throws, thats fine and the test should pass, as we're
        # only testing invalid sequences anyway.
        msg.save!

        # get the saved message back and check that it is identical - i.e:
        # its OK to accept invalid UTF-8 as long as we return it unmodified.
        db_msg = msg.class.find(msg.id)
        assert_equal char, db_msg.title, "Database silently truncated message title"

      rescue ArgumentError => ex
        assert_equal ex.to_s, "invalid byte sequence in UTF-8"

      end
    end
  end

  def test_from_mail_plain
    mail = Mail.new do
      from "from@example.com"
      to "to@example.com"
      subject "Test message"
      date Time.now
      content_type "text/plain; charset=utf-8"
      body "This is a test & a message"
    end
    message = Message.from_mail(mail, users(:normal_user), users(:public_user))
    assert_equal users(:normal_user), message.sender
    assert_equal users(:public_user), message.recipient
    assert_equal mail.date, message.sent_on
    assert_equal "Test message", message.title
    assert_equal "This is a test & a message", message.body
    assert_equal "text", message.body_format
  end

  def test_from_mail_html
    mail = Mail.new do
      from "from@example.com"
      to "to@example.com"
      subject "Test message"
      date Time.now
      content_type "text/html; charset=utf-8"
      body "<p>This is a <b>test</b> &amp; a message</p>"
    end
    message = Message.from_mail(mail, users(:normal_user), users(:public_user))
    assert_equal users(:normal_user), message.sender
    assert_equal users(:public_user), message.recipient
    assert_equal mail.date, message.sent_on
    assert_equal "Test message", message.title
    assert_match /^ *This is a test & a message *$/, message.body
    assert_equal "text", message.body_format
  end

  def test_from_mail_multipart
    mail = Mail.new do
      from "from@example.com"
      to "to@example.com"
      subject "Test message"
      date Time.now

      text_part do
        content_type "text/plain; charset=utf-8"
        body "This is a test & a message in text format"
      end

      html_part do
        content_type "text/html; charset=utf-8"
        body "<p>This is a <b>test</b> &amp; a message in HTML format</p>"
      end
    end
    message = Message.from_mail(mail, users(:normal_user), users(:public_user))
    assert_equal users(:normal_user), message.sender
    assert_equal users(:public_user), message.recipient
    assert_equal mail.date, message.sent_on
    assert_equal "Test message", message.title
    assert_equal "This is a test & a message in text format", message.body
    assert_equal "text", message.body_format

    mail = Mail.new do
      from "from@example.com"
      to "to@example.com"
      subject "Test message"
      date Time.now

      html_part do
        content_type "text/html; charset=utf-8"
        body "<p>This is a <b>test</b> &amp; a message in HTML format</p>"
      end
    end
    message = Message.from_mail(mail, users(:normal_user), users(:public_user))
    assert_equal users(:normal_user), message.sender
    assert_equal users(:public_user), message.recipient
    assert_equal mail.date, message.sent_on
    assert_equal "Test message", message.title
    assert_match /^ *This is a test & a message in HTML format *$/, message.body
    assert_equal "text", message.body_format
  end

  def test_from_mail_prefix
    mail = Mail.new do
      from "from@example.com"
      to "to@example.com"
      subject "[OpenStreetMap] Test message"
      date Time.now
      content_type "text/plain; charset=utf-8"
      body "This is a test & a message"
    end
    message = Message.from_mail(mail, users(:normal_user), users(:public_user))
    assert_equal users(:normal_user), message.sender
    assert_equal users(:public_user), message.recipient
    assert_equal mail.date, message.sent_on
    assert_equal "Test message", message.title
    assert_equal "This is a test & a message", message.body
    assert_equal "text", message.body_format
  end

  private

  def make_message(char, count)
    message = messages(:unread_message)
    message.title = char * count
    message
  end

  def assert_message_ok(char, count)
    message = make_message(char, count)
    assert message.save!
    response = message.class.find(message.id) # stand by for some über-generalisation...
    assert_equal char * count, response.title, "message with #{count} #{char} chars (i.e. #{char.length * count} bytes) fails"
  end
end
