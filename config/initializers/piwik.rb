require "yaml"

if File.exist?(piwik_file = File.expand_path("../piwik.yml", __dir__))
  PIWIK = YAML.load_file(piwik_file)
end
