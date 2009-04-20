= Composite Primary Keys - Testing Readme

== Testing an adapter

There are tests available for the following adapters:

* ibmdb
* mysql
* oracle
* postgresql
* sqlite

To run the tests for on of the adapters, follow these steps (using mysql in the example):

* rake -T | grep mysql

    rake mysql:build_databases         # Build the MySQL test databases
    rake mysql:drop_databases          # Drop the MySQL test databases
    rake mysql:rebuild_databases       # Rebuild the MySQL test databases
    rake test_mysql                    # Run tests for test_mysql

* rake mysql:build_databases
* rake test_mysql

== Testing against different ActiveRecord versions (or Edge Rails)

ActiveRecord is a RubyGem within Rails, and is constantly being improved/changed on
its repository (http://dev.rubyonrails.org). These changes may create errors for the CPK
gem. So, we need a way to test CPK against Edge Rails, as well as officially released RubyGems.

The default test (as above) uses the latest RubyGem in your cache.

You can select an older RubyGem version by running the following:

* rake ar:set VERSION=1.14.4 test_mysql

== Edge Rails

Before you can test CPK against Edge Rails, you must checkout a copy of edge rails somewhere (see http://dev.rubyonrails.org for for examples)

* cd /path/to/gems
* svn co http://svn.rubyonrails.org/rails/trunk rails

Say the rails folder is /path/to/gems/rails

Three ways to run CPK tests for Edge Rails:

i)   Run:
  
        EDGE_RAILS_DIR=/path/to/gems/rails rake ar:edge test_mysql
        
ii)  In your .profile, set the environment variable EDGE_RAILS_DIR=/path/to/gems/rails, 
     and once you reload your profile, run:  
     
        rake ar:edge test_mysql
        
iii) Store the path in local/paths.rb. Run:

        cp local/paths.rb.sample local/paths.rb
        # Now set ENV['EDGE_RAILS_DIR']=/path/to/gems/rails
        rake ar:edge test_mysql

These are all variations of the same theme:

* Set the environment variable EDGE_RAILS_DIR to the path to Rails (which contains the activerecord/lib folder)
* Run: rake ar:edge test_<adapter>
  
