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
port, for example; [Osmosis,](http://wiki.openstreetmap.org/wiki/Osmosis) 
[CGImap.](https://github.com/zerebubuth/openstreetmap-cgimap)

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

## Coding style

When writing code it is generally a good idea to try and match your
formatting to that of any existing code in the same file, or to other
similar files if you are writing new code. Consistency of layout is
far more important that the layout itself as it makes reading code
much easier.

One golden rule of formatting -- please don't use tabs in your code
as they will cause the file to be formatted differently for different
people depending on how they have their editor configured.

## Testing

Having a good suite of tests is very important to the stability and
maintainability of any code base. The tests in the Rails port code are
by no means complete, but they are extensive, and must continue to be
so with any new functionality which is written. Tests are also useful
in giving others confidence in the code you've written, and can
greatly speed up the process of merging in new code.

When hacking, you should:

* Write new tests to cover the new functionality you've added.
* Where appropriate, modify existing tests to reflect new or changed
functionality.
* Never comment out or remove a test just because it doesn't pass.

## Comments

Sometimes it's not apparent from the code itself what it does, or,
more importantly, **why** it does that. Good comments help your fellow
developers to read the code and satisfy themselves that it's doing the
right thing.

When hacking, you should:

* Comment your code - don't go overboard, but explain the bits which
might be difficult to understand what the code does, why it does it
and why it should be the way it is.
* Check existing comments to ensure that they are not misleading.

## Committing

When you submit patches, the project maintainer has to read them and
understand them. This is difficult enough at the best of times, and
misunderstanding patches can lead to them being more difficult to
merge. To help with this, when submitting you should:

* Split up large patches into smaller units of functionality.
* Keep your commit messages relevant to the changes in each individual
unit.

When writing commit messages please try and stick to the same style as
other commits, namely:

* A one line summary, starting with a capital and with no full stop.
* A blank line.
* Full description, as proper sentences with capitals and full stops.

For simple commits the one line summary is often enough and the body
of the commit message can be left out.

## Sending the patches

If you have forked on GitHub then the best way to submit your patches is to
push your changes back to GitHub and then send a "pull request" on GitHub.

Otherwise you should either push your changes to a publicly visible git repository
and send the details to the [rails-dev](http://lists.openstreetmap.org/listinfo/rails-dev)
list or generate patches with `git format-patch` and send them to the
[rails-dev](http://lists.openstreetmap.org/listinfo/rails-dev) list.

