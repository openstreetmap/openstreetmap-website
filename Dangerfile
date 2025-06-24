# Get PR number
pr_number = github.pr_json["number"]

# Report if number of changed lines is > 500
if git.lines_of_code > 500
  warn("Number of updated lines of code is too large to be in one PR. Perhaps it should be separated into two or more?")
  auto_label.set(pr_number, "big-pr", "FBCA04")
else
  auto_label.remove("big-pr")
end

# Get list of translation files (except en.yml) which are modified
modified_yml_files = git.modified_files.select do |file|
  file.start_with?("config/locales") && File.extname(file) == ".yml" && File.basename(file) != "en.yml"
end

# Report if some translation file (except en.yml) is modified
if modified_yml_files.empty?
  auto_label.remove("inappropriate-translations")
else
  modified_files_str = modified_yml_files.map { |file| "`#{file}`" }.join(", ")
  warn("The following YAML files other than `en.yml` have been modified: #{modified_files_str}. Only `en.yml` is allowed to be changed. Translations are updated via Translatewiki, see CONTRIBUTING.md.")
  auto_label.set(pr_number, "inappropriate-translations", "B60205")
end

# Report if there are merge-commits in PR
if git.commits.any? { |c| c.parents.count > 1 }
  warn("Merge commits are found in PR. Please rebase to get rid of the merge commits in this PR, see CONTRIBUTING.md.")
  auto_label.set(pr_number, "merge-commits", "D93F0B")
else
  auto_label.remove("merge-commits")
end

# Check if Gemfile is modified but Gemfile.lock is not
gemfile_modified = git.modified_files.include?("Gemfile")
gemfile_lock_modified = git.modified_files.include?("Gemfile.lock")
if gemfile_modified && !gemfile_lock_modified
  warn("Gemfile was updated, but Gemfile.lock wasn't updated. Usually, when Gemfile is updated, you should run `bundle install` to update Gemfile.lock.")
  auto_label.set(pr_number, "gemfile-lock-outdated", "F9D0C4")
else
  auto_label.remove("gemfile-lock-outdated")
end
