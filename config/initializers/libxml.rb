require 'rubygems'
gem 'libxml-ruby', '>= 1.1.1'
require 'libxml'

# This is required otherwise libxml writes out memory errors to
# the standard output and exits uncleanly
LibXML::XML::Error.set_handler do |message|
  raise message
end
