# Description

This is the Rails port, the [Ruby on Rails](http://rubyonrails.org/)
application that powers [OpenStreetMap](http://www.openstreetmap.org).

The Rails port provides almost all the services which are available 
on the OpenStreetMap site, including:

* The web site itself, including the edit pages.
* The editing [API](http://wiki.openstreetmap.org/wiki/API_v0.6).
* Browse pages - a web front-end to the OpenStreetMap data.
* The user system, including preferences, diary entries, friends and
  user-to-user messaging.
* GPX uploads, browsing and API.

There are some non-Rails services which the site includes, for 
example; tiles, geocoding, GPX file loading. There are also some
utilities which provide other services on the OpenStreetMap site,
or improve its function, but are not integrated with the Rails 
port, for example; Osmosis, CGImap.

# License

This software is licensed under the [GNU General Public License 2.0](http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt),
a copy of which can be found in the LICENSE file.

# Running it

You can find documentation on [how to setup and
run](http://wiki.openstreetmap.org/wiki/The_Rails_Port) the software
on the OpenStreetMap wiki.

# Hacking it

The canonical Git repository for this software is hosted at
[git.openstreetmap.org](http://git.openstreetmap.org/?p=rails.git),
but much of the development is done on GitHub and for most people
[this repository on Github](https://github.com/openstreetmap/openstreetmap-website)
will be a better place to start.

Anybody hacking on the code is welcome to join the
[rails-dev](http://lists.openstreetmap.org/listinfo/rails-dev) mailing
list where other people hacking on the code hang out and will be happy
to help with any problems you may encounter. If you are looking for a
project to help out with, please take a look at the list of 
[Top Ten Tasks](http://wiki.openstreetmap.org/wiki/Top_Ten_Tasks) that
EWG maintains on the wiki.

There are also weekly IRC meetings, at 1800 GMT on Mondays in #osm-ewg on
the OFTC network where questions can be asked and ideas discussed. For more 
information, please see [the EWG page]
(http://www.osmfoundation.org/wiki/Engineering_Working_Group#Meetings). You can
join the channel using your favourite IRC client or [irc.openstreetmap.org](http://irc.openstreetmap.org/).

## Rails

If you're not already familiar with Ruby on Rails then it's probably
worth having a look at [Rails Guides](http://guides.rubyonrails.org/) for an introduction.

While working with Rails you will probably find the [API documentation](http://api.rubyonrails.org/)
helpful as a reference.
