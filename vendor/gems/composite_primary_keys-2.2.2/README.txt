= Composite Primary Keys for ActiveRecords

== Summary

ActiveRecords/Rails famously doesn't support composite primary keys. 
This RubyGem extends the activerecord gem to provide CPK support.

== Installation

    gem install composite_primary_keys
    
== Usage
  
    require 'composite_primary_keys'
    class ProductVariation
      set_primary_keys :product_id, :variation_seq
    end
    
    pv = ProductVariation.find(345, 12)
    
It even supports composite foreign keys for associations.

See http://compositekeys.rubyforge.org for more.

== Running Tests

See test/README.tests.txt

== Url

http://compositekeys.rubyforge.org

== Questions, Discussion and Contributions

http://groups.google.com/compositekeys

== Author

Written by Dr Nic Williams, drnicwilliams@gmail
Contributions by many!

