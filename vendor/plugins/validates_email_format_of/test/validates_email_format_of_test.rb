require File.dirname(__FILE__) + '/test_helper'

class ValidatesEmailFormatOfTest < TEST_CASE
  fixtures :people, :peoplemx

  def setup
    @valid_email = 'valid@example.com'
    @invalid_email = 'invalid@example.'
  end

  def test_without_activerecord
    assert_nil ValidatesEmailFormatOf::validate_email_format('valid@example.com')
    err = ValidatesEmailFormatOf::validate_email_format('valid@example-com')
    assert_equal 1, err.size
  end

  def test_should_allow_valid_email_addresses
    ['valid@example.com',
     'Valid@test.example.com',
     'valid+valid123@test.example.com',
     'valid_valid123@test.example.com',
     'valid-valid+123@test.example.co.uk',
     'valid-valid+1.23@test.example.com.au',
     'valid@example.co.uk',
     'v@example.com',
     'valid@example.ca',
     'valid_@example.com',
     'valid123.456@example.org',
     'valid123.456@example.travel',
     'valid123.456@example.museum',
     'valid@example.mobi',
     'valid@example.info',
     'valid-@example.com',
  # from RFC 3696, page 6
     'customer/department=shipping@example.com',
     '$A12345@example.com',
     '!def!xyz%abc@example.com',
     '_somename@example.com',
  # apostrophes
     "test'test@example.com",
     ].each do |email|
      p = create_person(:email => email)
      save_passes(p, email)
    end
  end

  def test_should_not_allow_invalid_email_addresses
    ['invalid@example-com',
  # period can not start local part
     '.invalid@example.com',
  # period can not end local part
     'invalid.@example.com', 
  # period can not appear twice consecutively in local part
     'invali..d@example.com',
  # should not allow underscores in domain names
     'invalid@ex_mple.com',
     'invalid@example.com.',
     'invalid@example.com_',
     'invalid@example.com-',
     'invalid-example.com',
     'invalid@example.b#r.com',
     'invalid@example.c',
     'invali d@example.com',
     'invalidexample.com',
     'invalid@example.'].each do |email|
      p = create_person(:email => email)
      save_fails(p, email)
    end
  end

  # from http://www.rfc-editor.org/errata_search.php?rfc=3696
  def test_should_allow_quoted_characters
    ['"Abc\@def"@example.com',     
     '"Fred\ Bloggs"@example.com',
     '"Joe.\\Blow"@example.com',
     ].each do |email|
      p = create_person(:email => email)
      save_passes(p, email)
    end
  end

  # from http://tools.ietf.org/html/rfc3696, page 5
  # corrected in http://www.rfc-editor.org/errata_search.php?rfc=3696
  def test_should_not_allow_escaped_characters_without_quotes
    ['Fred\ Bloggs_@example.com',
     'Abc\@def+@example.com',
     'Joe.\\Blow@example.com'
     ].each do |email|
      p = create_person(:email => email)
      save_fails(p, email)
    end
  end

  def test_should_check_length_limits
    ['aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@example.com',
     'test@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.com'
     ].each do |email|
      p = create_person(:email => email)
      save_fails(p, email)
    end
  end

  def test_should_respect_validate_on_option
    p = create_person(:email => @valid_email)
    save_passes(p)
    
    # we only asked to validate on :create so this should fail
    assert p.update_attributes(:email => @invalid_email)
    assert_equal @invalid_email, p.email
  end
  
  def test_should_allow_custom_error_message
    p = create_person(:email => @invalid_email)
    save_fails(p)
    assert_equal 'fails with custom message', p.errors.on(:email)
  end

  def test_should_allow_nil
    p = create_person(:email => nil)
    save_passes(p)
  end

  def test_check_mx
    pmx = MxRecord.new(:email => 'test@dunae.ca')
    save_passes(pmx)

    pmx = MxRecord.new(:email => 'test@example.com')
    save_fails(pmx)
  end

  protected
    def create_person(params)
      Person.new(params)
    end

    def save_passes(p, email = '')
      assert p.valid?, " validating #{email}"
      assert p.save
      assert_nil p.errors.on(:email)
    end
    
    def save_fails(p, email = '')
      assert !p.valid?, " validating #{email}"
      assert !p.save
      assert p.errors.on(:email)
    end
end
