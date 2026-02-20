# Contributing

This guide covers our development workflow, coding standards, and how to get your changes merged.

## Table of Contents

1. [Getting Started](#getting-started)
2. [How to Contribute](#how-to-contribute)
3. [Code Quality Guidelines](#code-quality-guidelines)
4. [Submitting Changes](#submitting-changes)
5. [Localization (i18n)](#localization-i18n)
6. [Copyright Attribution](#copyright-attribution)

## Getting Started

### Useful Resources

* https://www.ruby-lang.org/ - The homepage of Ruby which has more links and some great tutorials.
* https://rubyonrails.org/ - The homepage of Rails, also has links and tutorials.

### Finding Opportunities to Contribute

> [!NOTE]
> We don't assign issues to individual contributors. You are welcome to work on any issue, and there's no need to ask first.
> For more details see [our FAQ](doc/FAQ.md)

We welcome the community to contribute to this repository in any form:

- **Documentation:** are the docs clear? Are they correct? Did you come across
  any issues when trying to follow them? Could something be explained more
  clearly?
- **Bug reporting:** something is broken on the website? Something doesn't work
  as expected? Create an issue and give as much detail as possible, so that
  others can understand the context, the conditions in which it happens,
  and your use case. Or comment on an existing report if one already exists.
- **Bug triage:** we receive many issue reports. Can you take one and reproduce
  it? Can you add more detail that could help others fix the issue more
  easily? Or perhaps you think it's not really an issue and should be left
  as is? Come to the issue tracker and let us know your thoughts.
- **Feature discussion:** is there a use case that is not covered? Is there
  something that you wish that the website did, or did differently? Create
  an issue to discuss it, or comment on an existing issue if it's already
  being discussed. Try to express your use case in a way that helps understand
  your needs well, and frames them in the context of the wider community.
- **Code reviews:** at any given point, there will be pending PRs, waiting for
  reviews. Can you take on one, understand what it's trying to do, and
  provide actionable feedback? Is the code clear, maintainable, and readable?
  Would you do something differently? Are useful, clear tests provided?
- **Code:** take an existing issue and try to fix it, or try to implement
  an idea.
- And probably other ideas not captured here.

Bear in mind that OSM attracts very diverse contributors with very different
needs. Others may have needs different from yours, and reaching a consensus
is sometimes difficult.

If you want to code a feature to this repository, we recommend that you ask
for feedback early and often. Create an issue to discuss it, or start with a
["draft" PR](https://github.blog/news-insights/product-news/introducing-draft-pull-requests/)
that shows your intention clearly and can be used to provide early
feedback. We are not strict on how you communicate, but it's important that
you do communicate, early and often, so that you can get feedback quickly.
This will help you get buy-in from the maintainers, which will translate into
less waste for everyone and a much easier time getting your code merged.

Bug fixes should be more straighforward than new features, but the same
guidance applies. If it turns out to be more complex than initially expected,
stop for a moment and seek feedback, be it in an issue or in a draft PR.

If you are looking for some additional inspiration, you may want to have
a look at the [Roadmap](https://github.com/openstreetmap/software-roadmap)
that the OSM Foundation published in 2025. This lists items that OSMF
would like to focus on, and is not limited to this website. Note that this
is not a mandatory list of the contributions that will be accepted. You
can choose to ignore it and provide your own contributions. After all,
the mission of the OSMF is to support OSM, not to control it.

## How to Contribute

Here's the typical contribution workflow:

1. **Find an Issue**: Browse our [issues](https://github.com/openstreetmap/openstreetmap-website/issues) or identify a bug/feature you'd like to work on
2. **Fork, Clone & Branch**: Fork the repository, clone it to your local machine, and create a new branch for your work. Avoid working directly on the `master` branch.
3. **Set Up**: Follow the [installation guide](doc/INSTALL.md) to set up your development environment
4. **Develop**: Make your changes following our [code quality guidelines](#code-quality-guidelines)
5. **Test**: Write tests for your changes and ensure all existing tests pass
6. **Commit**: Write clear commit messages following our [guidelines](#committing)
7. **Submit a Pull Request**: Create a pull request with a clear description of your changes
  - In fact, we suggest that you publish a draft PR early in the process, so
    that maintainers can provide feedback and guidance as soon as possible.

## Code Quality Guidelines

### Coding Style

We use [Rubocop](https://github.com/rubocop-hq/rubocop) (for ruby files), [ESLint](https://eslint.org/) (for javascript files), and [ERB Lint](https://github.com/Shopify/erb-lint) (for erb templates) to help maintain consistency in our code. You can run these utilities during development to check that your code matches our guidelines:

```bash
bundle exec rubocop
bundle exec rails eslint
bundle exec erb_lint .
```

You can automatically fix many linting issues with:

```bash
bundle exec rubocop -a
bundle exec rails eslint:fix
bundle exec erb_lint . --autocorrect
```

> [!NOTE]
> Use `bundle exec rails eslint:fix` instead of the standard `eslint --fix` option, which is silently ignored in this Rails project.

> [!TIP]
> You can also install hooks to have git run checks automatically when you commit using [overcommit](https://github.com/sds/overcommit) with:
>
> ```bash
> bundle exec overcommit --install
> ```

### Testing

> [!IMPORTANT]
> Having a good suite of tests is very important to the stability and maintainability of any code base. The tests in the `openstreetmap-website` code are by no means complete, but they are extensive, and must continue to be so with any new functionality which is written. Tests are also useful in giving others confidence in the code you've written, and can greatly speed up the process of merging in new code.

When contributing, you should:

* Write new tests to cover the new functionality you've added.
* Where appropriate, modify existing tests to reflect new or changed functionality.

> [!WARNING]
> Never comment out or remove a test just because it doesn't pass.

You can run the existing test suite with:

```bash
bundle exec rails test:all
```

You can run javascript tests with:

```bash
RAILS_ENV=test bundle exec teaspoon
```

You can view test coverage statistics by browsing the `coverage` directory.

The tests are automatically run on Pull Requests and other commits via github actions. The results shown are within the PR display on github.

> [!TIP]
> **System tests** use Selenium with Firefox for browser automation. On Ubuntu 24.04, if Firefox is installed via snap, you may need to override the Firefox binary path in `config/settings/test.local.yml`:
>
> ```yaml
> system_test_firefox_binary: /snap/firefox/current/usr/lib/firefox/firefox
> ```

### Static Analysis

We also perform static analysis of our code. You can run the analysis yourself with:

```bash
bundle exec brakeman -q
```

### Comments

Sometimes it's not apparent from the code itself what it does, or, more importantly, **why** it does that. Good comments help your fellow developers to read the code and satisfy themselves that it's doing the right thing.

When contributing, you should:

* Comment your code where necessary - explain the bits which might be difficult to understand what the code does, why it does it and why it should be the way it is.
* Check existing comments to ensure that they are not misleading.

## Submitting Changes

### Committing

When you submit your changes, the project maintainers have to read them and understand them. This is difficult enough at the best of times, and misunderstanding commits can lead to them being more difficult to merge. To help with this, when committing you should:

* Split up large commits into smaller units of functionality.
* Keep your commit messages relevant to the changes in each individual commit.

When writing commit messages please try and stick to the same style as other commits, namely:

* A one line summary, starting with a capital and with no full stop.
* A blank line.
* Full description, as proper sentences with capitals and full stops.

> [!TIP]
> Use the imperative verb form in your summary line (e.g., "Add feature" not "Added feature"). A good test is whether your summary line completes the sentence "This commit will...". For example: "This commit will **Fix user login validation**" or "This commit will **Update README installation steps**".

For simple commits the one line summary is often enough and the body of the commit message can be left out.

### Pull Requests

If you have forked on GitHub then the best way to submit your patches is to push your changes back to GitHub and open a Pull Request on GitHub.

If your pull request is small, for example one or two commits each containing only a few lines of code, then it is easy for the maintainers to review.

Please ensure your commit history is clean and avoid including "fixup" commits. If you have added a fixup commit (for example to fix a rubocop warning, or because you changed your own new code) please combine the fixup commit into the commit that introduced the problem. `git rebase -i` is very useful for this.

> [!IMPORTANT]
> If you are creating a larger pull request, then please help the maintainers with making the reviews as straightforward as possible:
>
> * The smaller the PR, the easier it is to review. In particular if a PR is too large to review in one sitting, or if changes are requested, then the maintainer needs to repeatedly re-read code that has already been considered.
> * The commit history is important. This is a large codebase, developed over many years by many developers. We frequently need to read the commit history (for example using `git blame`) to figure out what is going on. So small, understandable, and relevant commits are important for other developers looking back at your work in future.

> [!TIP]
> If you are creating a large pull request then please:
>
> * Consider splitting your pull request into multiple PRs. If part of your work can be considered standalone, or is a foundation for the rest of your work, please submit it separately first.
> * Avoid including "merge" commits. If your PR can no longer be merged cleanly (for example, an unrelated change to Gemfile.lock on master now conflicts with your PR) then please rebase your PR onto the latest master. This allows you to fix the conflicts, while keeping the PR a straightforward list of commits. If there are no conflicts, then there is no need to rebase anything.

## Localization (i18n)

> [!IMPORTANT]
> If you make a change that involves the locale files (in `config/locales`) then please only submit changes to the `en.yml` file. The other files are updated via [Translatewiki](https://translatewiki.net/wiki/Translating:OpenStreetMap) and should not be included in your pull request.

## Copyright Attribution

The list of attributions on the /copyright page is managed by the [OSMF Licensing Working Group (LWG)](https://wiki.osmfoundation.org/wiki/Licensing_Working_Group).

> [!IMPORTANT]
> If you want to add another attribution, or make changes to the text of an existing attribution, please follow these steps:
>
> * First, contact the LWG to discuss your proposed changes.
> * If the LWG approves, please create a pull request with your proposed changes.
> * Finally, please ask the LWG to formally approve the wording used in the pull request (by having an LWG member comment on the PR).
>
> When we have formal confirmation from LWG, we can go ahead and merge the PR.
