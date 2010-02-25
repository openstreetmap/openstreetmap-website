# encoding: utf-8

module ValidatesEmailFormatOf
  LocalPartSpecialChars = Regexp.escape('!#$%&\'*-/=?+-^_`{|}~')
  LocalPartUnquoted = '(([[:alnum:]' + LocalPartSpecialChars + ']+[\.\+]+))*[[:alnum:]' + LocalPartSpecialChars + '+]+'
  LocalPartQuoted = '\"(([[:alnum:]' + LocalPartSpecialChars + '\.\+]*|(\\\\[\u0001-\uFFFF]))*)\"'
  Regex = Regexp.new('^((' + LocalPartUnquoted + ')|(' + LocalPartQuoted + ')+)@(((\w+\-+)|(\w+\.))*\w{1,63}\.[a-z]{2,6}$)', Regexp::EXTENDED | Regexp::IGNORECASE)
end

module ActiveRecord
  module Validations
    module ClassMethods
      # Validates whether the value of the specified attribute is a valid email address
      #
      #   class User < ActiveRecord::Base
      #     validates_email_format_of :email, :on => :create
      #   end
      #
      # Configuration options:
      # * <tt>message</tt> - A custom error message (default is: " does not appear to be a valid e-mail address")
      # * <tt>on</tt> - Specifies when this validation is active (default is :save, other options :create, :update)
      # * <tt>allow_nil</tt> - Allow nil values (default is false)
      # * <tt>allow_blank</tt> - Allow blank values (default is false)
      # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
      #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
      #   method, proc or string should return or evaluate to a true or false value.
      # * <tt>unless</tt> - See <tt>:if</tt>
      def validates_email_format_of(*attr_names)
        options = { :message => ' does not appear to be a valid e-mail address', 
                    :on => :save, 
                    :allow_nil => false,
                    :allow_blank => false,
                    :with => ValidatesEmailFormatOf::Regex }

        options.update(attr_names.pop) if attr_names.last.is_a?(Hash)

        validates_each(attr_names, options) do |record, attr_name, value|
          v = value.to_s

          # local part max is 64 chars, domain part max is 255 chars
          # TODO: should this decode escaped entities before counting?
          begin
            domain, local = v.reverse.split('@', 2)
          rescue
            record.errors.add(attr_name, options[:message])
            next
          end

          unless v =~ options[:with] and not v =~ /\.\./ and domain.length <= 255 and local.length <= 64
            record.errors.add(attr_name, options[:message])
          end
        end
      end
    end   
  end
end
