# This hack prevents the gem oauth 0.4.7 raising an exception on load
# with Ruby >=3.2. Please remove this file once that version of the
# oauth gem is not used anymore.
File.singleton_class.alias_method(:exists?, :exist?) unless File.singleton_class.method_defined?(:exists?)
