# This is required otherwise libxml writes out memory errors to
# the standard output and exits uncleanly 
# Changed method due to deprecation of the old register_error_handler
# http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Parser.html#M000076
# So set_handler is used instead
# http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Error.html#M000334
LibXML::XML::Error.set_handler do |message|
  raise message
end
