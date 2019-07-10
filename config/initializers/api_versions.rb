# This controls which versions of the API are enabled

# `all_api_versions` is the complete list of versions that this codebase understands
all_api_versions = ["0.6"]

# `deployed_api_versions` is the user-controlled setting for which versions they would like
# to be deployed. The `api_versions` setting is the intersection of these two lists.
Settings.add_source!(:api_versions => Settings.deployed_api_versions & all_api_versions)
Settings.reload!
