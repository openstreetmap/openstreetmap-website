require "yaml"

if File.exists?(piwik_file = File.expand_path("../../piwik.yml", __FILE__))
  PIWIK = YAML.load_file(piwik_file)
end
