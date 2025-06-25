task "eslint" => "eslint:check"

def yarn_path
  Rails.root.join("bin/yarn").to_s
end

def config_file
  Rails.root.join("config/eslint.config.mjs").to_s
end

namespace "eslint" do
  task :check => :environment do
    system(yarn_path, "run", "eslint", "-c", config_file, "--no-warn-ignored", Rails.root.to_s) || abort
  end

  task :fix => :environment do
    system(yarn_path, "run", "eslint", "-c", config_file, "--no-warn-ignored", "--fix", Rails.root.to_s) || abort
  end
end
