# This is required otherwise libxml writes out memory errors to
# the standard output and exits uncleanly 
LibXML::XML::Parser.register_error_handler do |message|
  raise message
end
