* https://www.ruby-lang.org/ - The homepage of Ruby which has more links and some great tutorials.
* http://rubyonrails.org/ - The homepage of Rails, also has links and tutorials

## Coding style

We use [Rubocop](https://github.com/rubocop-hq/rubocop) (for ruby files)
and [ERB Lint](https://github.com/Shopify/erb-lint) (for erb templates)
to help maintain consistency in our code. You can run these utilities during
development to check that your code matches our guidelines:

```
bundle exec rubocop
bundle exec rake eslint
bundle exec erblint .
```

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

You can run the existing test suite with:

```
bundle exec rake test
```

You can view test coverage statistics by browsing the `coverage` directory.

The tests are automatically run on Pull Requests and other commits with the
results shown on [Travis CI](https://travis-ci.org/openstreetmap/openstreetmap-website).

## Static Analysis

We also perform static analysis of our code. You can run the analysis yourself with:

```
bundle exec brakeman -q
```

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

## i18n

If you make a change that involve the locale files (in `config/locales`) then please
only submit changes to the `en.yml` file. The other files are updated via
[Translatewiki](https://translatewiki.net/wiki/Translating:OpenStreetMap) and should
not be included in your pull request.

### Nominatim prefixes

I18n keys under the `geocoder.search_osm_nominatim` keyspace are managed by the
Nominatim maintainers. From time to time they run stats over the Nominatim
database, and update the list of available keys manually.

Adding or removing keys to this list is therefore discouraged, but contributions
to the descriptive texts are welcome.

## Code Documentation

To generate the HTML documentation of the API/rails code, run the command

```
rake doc:app
```

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

### Issue/Pull Request Labels

We use GitHub labels to keep track of issues.  Some guidelines:



Light blue labels are for **components**, the specific parts of the openstreetmap website.

* <sub>[![notes][notes]][notes_link]
[![moderation][moderation]][moderation_link]
[![diaries][diaries]][diaries_link]
[![mapview][mapview]][mapview_link]
[![changesets][changesets]][changesets_link]</sub>

[notes]: http://labl.es/svg?text=notes&bgcolor=c5def5
[moderation]: http://labl.es/svg?text=moderation&bgcolor=c5def5
[diaries]: http://labl.es/svg?text=diaries&bgcolor=c5def5
[mapview]: http://labl.es/svg?text=mapview&bgcolor=c5def5
[changesets]: http://labl.es/svg?text=changesets&bgcolor=c5def5

[notes_link]: https://github.com/openstreetmap/openstreetmap-website/issues?q=is%3Aopen+is%3Aissue+label%3Anotes
[moderation_link]: https://github.com/openstreetmap/openstreetmap-website/issues?q=is%3Aopen+is%3Aissue+label%moderation
[diaries_link]: https://github.com/openstreetmap/openstreetmap-website/issues?q=is%3Aopen+is%3Aissue+label%3Adiaries
[mapview_link]: https://github.com/openstreetmap/openstreetmap-website/issues?q=is%3Aopen+is%3Aissue+label%3Amapview
[changesets_link]: https://github.com/openstreetmap/openstreetmap-website/issues?q=is%3Aopen+is%3Aissue+label%3Achangesets

Other Labels:

* <sub>[![good-first-issue][good-first-issue]][good-first-issue_link]</sub> -
Best for new contributors.  No experience necessary!
* <sub>[![help-wanted][help-wanted]][help-wanted_link]</sub> -
For more intermediate contributors, probably requires investigation or knowledge of openstreetmap-website code.
* <sub>[![awaiting upstream][awaiting_upstream]][awaiting_upstream_link]</sub> -
Awaiting Upstream. These issues won't be resolved until changes are made upstream.
* <sub>[![enhancement][enhancement]][enhancement_link]</sub> -
Enhancements. These are features that improve already supported .
* <sub>[![dx][dx]][dx_link]</sub> -
Developer Experience. The things that help with development (Docker, Vagrant, Rake, etc.)

[good-first-issue]: http://labl.es/svg?text=good%20first%20issue&bgcolor=0e8a16
[help-wanted]: http://labl.es/svg?text=help%20wanted&bgcolor=1D76DB
[awaiting_upstream]: http://labl.es/svg?text=awaiting%20upstream&bgcolor=E0D05C
[enhancement]: http://labl.es/svg?text=enhancment&bgcolor=E105D8
[changes_requested]: http://labl.es/svg?text=changes%20requested&bgcolor=5319E7

[good-first-issue_link]: https://github.com/openstreetmap/openstreetmap-website/issues?q=is%3Aopen+is%3Aissue+label%3A%22good%20first%20issue%22
[help-wanted_link]: https://github.com/openstreetmap/openstreetmap-website/issues?q=is%3Aopen+is%3Aissue+label%3A%22help%20wanted%22
[awaiting_upstream_link]: https://github.com/openstreetmap/openstreetmap-website/issues?q=is%3Aopen+is%3Aissue+label%3A%22awaiting%20upstream%22
[enhancement_link]: https://github.com/openstreetmap/openstreetmap-website/issues?q=is%3Aopen+is%3Aissue+label%3Aenhancement
[changes_requested_link]: https://github.com/openstreetmap/openstreetmap-website/pulls?q=is%3Apr+is%3Aopen+label%3A%22changes+requested%22

PR Labels:

* <sub>[![changes requested][changes_requested]][changes_requested_link]</sub> -
Changes Requested. More changes needed before a pull request will be accepted.
* <sub>[![work-in-progress][wip]][wip_link]</sub> -
Work in Progress. Pull requests that are not ready to be merged.

[wip]: http://labl.es/svg?text=work-in-progress&bgcolor=dddddd
[dx]: http://labl.es/svg?text=dx&bgcolor=0052CC


[wip_link]: https://github.com/openstreetmap/openstreetmap-website/labels/work-in-progress
[dx_link]: https://github.com/openstreetmap/openstreetmap-website/issues?q=is%3Aopen+is%3Aissue+label%3Adx

## Sending the patches

If you have forked on GitHub then the best way to submit your patches is to
push your changes back to GitHub and then send a "pull request" on GitHub.

Otherwise you should either push your changes to a publicly visible git repository
and send the details to the [rails-dev](https://lists.openstreetmap.org/listinfo/rails-dev)
list or generate patches with `git format-patch` and send them to the
[rails-dev](https://lists.openstreetmap.org/listinfo/rails-dev) list.
