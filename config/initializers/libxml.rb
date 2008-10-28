#require 'rubygems'
#gem 'libxml-ruby', '>= 0.8.3'
#require 'libxml'

# Is this really needed?
LibXML::XML::Parser.register_error_handler do |message|
  raise message
end
