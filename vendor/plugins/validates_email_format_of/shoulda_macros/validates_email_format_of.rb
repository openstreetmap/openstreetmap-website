module ValidatesEmailFormatOf
  module Shoulda
    def should_validate_email_format_of(field)
      metaclass = (class << self; self; end)
      metaclass.send(:define_method,:should_allow_values) do |klass,*values|
        should_allow_values_for(field, *values)
      end
      metaclass.send(:define_method,:should_not_allow_values) do |klass, *values|
        should_not_allow_values_for(field, values, :message => /valid e-mail/)
      end
      should_validate_email_format_of_klass(model_class, field)
    end

    def should_validate_email_format_of_klass(klass, field)
      context 'Typical valid email' do
        should_allow_values(klass,
          'valid@example.com',
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
          'valid-@example.com')
      end
      
      context 'valid email from RFC 3696, page 6' do
        should_allow_values(klass,
          'customer/department=shipping@example.com',
          '$A12345@example.com',
          '!def!xyz%abc@example.com',
          '_somename@example.com')
      end
      
      context 'valid email with apostrophe' do
        should_allow_values(klass, "test'test@example.com")
      end
      
      context 'valid email from http://www.rfc-editor.org/errata_search.php?rfc=3696' do
        should_allow_values(klass,
          '"Abc\@def"@example.com',     
          '"Fred\ Bloggs"@example.com',
          '"Joe.\\Blow"@example.com')
      end
      
      context 'Typical invalid email' do
        should_not_allow_values(klass,
          'invalid@example-com',
          'invalid@example.com.',
          'invalid@example.com_',
          'invalid@example.com-',
          'invalid-example.com',
          'invalid@example.b#r.com',
          'invalid@example.c',
          'invali d@example.com',
          'invalidexample.com',
          'invalid@example.')
      end
      
      context 'invalid email with period starting local part' do
        should_not_allow_values(klass,'.invalid@example.com')
      end
      
      context 'invalid email with period ending local part' do
        should_not_allow_values(klass, 'invalid.@example.com')
      end
      
      context 'invalid email with consecutive periods' do
        should_not_allow_values(klass, 'invali..d@example.com')
      end
      
      # corrected in http://www.rfc-editor.org/errata_search.php?rfc=3696
      context 'invalid email from http://tools.ietf.org/html/rfc3696, page 5' do
        should_not_allow_values(klass,
          'Fred\ Bloggs_@example.com',
          'Abc\@def+@example.com',
          'Joe.\\Blow@example.com')
      end

      context 'invalid email exceeding length limits' do
        should_not_allow_values(klass,
          "#{'a' * 65}@example.com",
          "test@#{'a'*252}.com")
      end
    end
  end
end

Test::Unit::TestCase.extend(ValidatesEmailFormatOf::Shoulda)
