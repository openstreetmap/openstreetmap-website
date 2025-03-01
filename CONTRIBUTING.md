# Contributing

* https://www.ruby-lang.org/ - The homepage of Ruby which has more links and some great tutorials.
* https://rubyonrails.org/ - The homepage of Rails, also has links and tutorials.

## Assigning Issues

We don't assign issues to individual contributors. You are welcome to work on any
issue, and there's no need to ask first.

For more details see [our FAQ](FAQ.md)]

## Coding style

We use [Rubocop](https://github.com/rubocop-hq/rubocop) (for ruby files)
and [ERB Lint](https://github.com/Shopify/erb-lint) (for erb templates)
to help maintain consistency in our code. You can run these utilities during
development to check that your code matches our guidelines:

```
bundle exec rubocop
bundle exec rails eslint
bundle exec erb_lint .
```

You can also install hooks to have git run checks automatically when
you commit using [overcommit](https://github.com/sds/overcommit) with:

```
bundle exec overcommit --install
```

## Testing

Having a good suite of tests is very important to the stability and
maintainability of any code base. The tests in the `openstreetmap-website` code are
by no means complete, but they are extensive, and must continue to be
so with any new functionality which is written. Tests are also useful
in giving others confidence in the code you've written, and can
greatly speed up the process of merging in new code.

When contributing, you should:

* Write new tests to cover the new functionality you've added.
* Where appropriate, modify existing tests to reflect new or changed
functionality.
* Never comment out or remove a test just because it doesn't pass.

You can run the existing test suite with:

```
bundle exec rails test:all
```

You can run javascript tests with:

```
RAILS_ENV=test bundle exec teaspoon
```

You can view test coverage statistics by browsing the `coverage` directory.

The tests are automatically run on Pull Requests and other commits via github
actions. The results shown are within the PR display on github.

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

When contributing, you should:

* Comment your code where necessary - explain the bits which
might be difficult to understand what the code does, why it does it
and why it should be the way it is.
* Check existing comments to ensure that they are not misleading.

## i18n

If you make a change that involves the locale files (in `config/locales`) then please
only submit changes to the `en.yml` file. The other files are updated via
[Translatewiki](https://translatewiki.net/wiki/Translating:OpenStreetMap) and should
not be included in your pull request.

### Copyright attribution

The list of attributions on the /copyright page is managed by the [OSMF Licensing
Working Group (LWG)](https://wiki.osmfoundation.org/wiki/Licensing_Working_Group).

If you want to add another attribution, or make changes to the text of an existing
attribution, please follow these steps:

* First, contact the LWG to discuss your proposed changes.
* If the LWG approves, please create a pull request with your proposed changes.
* Finally, please ask the LWG to formally approve the wording used in the pull request
  (by having an LWG member comment on the PR).

When we have formal confirmation from LWG, we can go ahead and merge the PR.

## Committing

When you submit your changes, the project maintainers have to read them and
understand them. This is difficult enough at the best of times, and
misunderstanding commits can lead to them being more difficult to
merge. To help with this, when committing you should:

* Split up large commits into smaller units of functionality.
* Keep your commit messages relevant to the changes in each individual
commit.

When writing commit messages please try and stick to the same style as
other commits, namely:

* A one line summary, starting with a capital and with no full stop.
* A blank line.
* Full description, as proper sentences with capitals and full stops.

For simple commits the one line summary is often enough and the body
of the commit message can be left out.

## Pull Requests

If you have forked on GitHub then the best way to submit your patches is to
push your changes back to GitHub and then send a "pull request" on GitHub.

If your pull request is small, for example one or two commits each containing
only a few lines of code, then it is easy for the maintainers to review.

If you are creating a larger pull request, then please help the maintainers
with making the reviews as straightforward as possible:

* The smaller the PR, the easier it is to review. In particular if a PR is too
  large to review in one sitting, or if changes are requested, then the
  maintainer needs to repeatedly re-read code that has already been considered.
* The commit history is important. This is a large codebase, developed over many
  years by many developers. We frequently need to read the commit history (for example
  using `git blame`) to figure out what is going on. So small, understandable,
  and relevant commits are important for other developers looking back at your
  work in future.

If you are creating a large pull request then please:

* Consider splitting your pull request into multiple PRs. If part of your work
  can be considered standalone, or is a foundation for the rest of your work,
  please submit it separately first.
* Avoid including "fixup" commits. If you have added a fixup commit (for example
  to fix a rubocop warning, or because you changed your own new code) please
  combine the fixup commit into the commit that introduced the problem.
  `git rebase -i` is very useful for this.
* Avoid including "merge" commits. If your PR can no longer be merged cleanly
  (for example, an unrelated change to Gemfile.lock on master now conflicts with
  your PR) then please rebase your PR onto the latest master. This allows you to
  fix the conflicts, while keeping the PR a straightforward list of commits. If
  there are no conflicts, then there is no need to rebase anything.
