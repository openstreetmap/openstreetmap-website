Composite Primary key support for db2 

== Driver Support ==

DB2 support requires the IBM_DB driver provided by http://rubyforge.org/projects/rubyibm/
project. Install using gem install ibm_db. Tested against version 0.60 of the driver.
This rubyforge project appears to be permenant location for the IBM adapter.
Older versions of the driver available from IBM Alphaworks will not work. 

== Driver Bug and workaround provided as part of this plugin ==

Unlike the basic quote routine available for Rails AR, the DB2 adapter's quote
method doesn't return " column_name = 1 " when string values (integers in string type variable) 
are passed for quoting numeric column. Rather it returns "column_name = '1'. 
DB2 doesn't accept single quoting numeric columns in SQL. Currently, as part of 
this plugin a fix is provided for the DB2 adapter since this plugin does 
pass string values like this. Perhaps a patch should be sent to the DB2 adapter
project for a permanant fix.

== Database Setup ==

Database must be manually created using a separate command. Read the rake task
for creating tables and change the db name, user and passwords accordingly.

== Tested Database Server version ==

This is tested against DB2 v9.1 in Ubuntu Feisty Fawn (7.04)

== Tested Database Client version ==

This is tested against DB2 v9.1 in Ubuntu Feisty Fawn (7.04)


