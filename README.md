# "The Rails Port"

[![Build Status](https://travis-ci.org/openstreetmap/openstreetmap-website.svg?branch=master)](https://travis-ci.org/openstreetmap/openstreetmap-website)
[![Coverage Status](https://coveralls.io/repos/openstreetmap/openstreetmap-website/badge.svg?branch=master)](https://coveralls.io/r/openstreetmap/openstreetmap-website?branch=master)

This is The Rails Port, the [Ruby on Rails](http://rubyonrails.org/)
application that powers the [OpenStreetMap](https://www.openstreetmap.org) website and API.
The software is also known as "openstreetmap-website".

This repository consists of:

* The web site, including user accounts, diary entries, user-to-user messaging
* The XML-based editing [API](https://wiki.openstreetmap.org/wiki/API_v0.6)
* The integrated versions of the [Potlatch](https://wiki.openstreetmap.org/wiki/Potlatch_1), [Potlatch 2](https://wiki.openstreetmap.org/wiki/Potlatch_2) and [iD](https://wiki.openstreetmap.org/wiki/ID) editors
* The Browse pages - a web front-end to the OpenStreetMap data
* The GPX uploads, browsing and API.

A fully-functional Rails Port installation depends on other services, including map tile
servers and geocoding services, that are provided by other software. The default installation
uses publicly-available services to help with development and testing.

# License

This software is licensed under the [GNU General Public License 2.0](https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt),
a copy of which can be found in the [LICENSE](LICENSE) file.

# Installation

The Rails Port is a Ruby on Rails application that uses PostgreSQL as its database, and has a large
number of dependencies for installation. For full details please see [INSTALL.md](INSTALL.md)

# Development

We're always keen to have more developers! Pull requests are very welcome.

* Bugs are recorded in the [issue tracker](https://github.com/openstreetmap/openstreetmap-website/issues).
* Some bug reports are also found on the [OpenStreetMap trac](https://trac.openstreetmap.org/) system, in the "[website](https://trac.openstreetmap.org/query?status=new&status=assigned&status=reopened&component=website&order=priority)" and "[api](https://trac.openstreetmap.org/query?status=new&status=assigned&status=reopened&component=api&order=priority)" components
* Translation is managed by [Translatewiki](https://translatewiki.net/wiki/Translating:OpenStreetMap)
* There is a [rails-dev@openstreetmap.org](https://lists.openstreetmap.org/listinfo/rails-dev) mailing list for development discussion.
* IRC - there is the #osm-dev channel on irc.oftc.net.

More details on contributing to the code are in the [CONTRIBUTING.md](CONTRIBUTING.md) file.

# Maintainers

* Tom Hughes [@tomhughes](https://github.com/tomhughes/)
* Andy Allan [@gravitystorm](https://github.com/gravitystorm/)
