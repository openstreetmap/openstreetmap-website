task "eslint" => "eslint:check"

namespace "eslint" do
  def yarn_path
    Rails.root.join("bin", "yarn").to_s
  end

  def config_file
    Rails.root.join("config", "eslint.json").to_s
  end

  def js_files
    Rails.application.assets.each_file.select do |file|
      file.ends_with?(".js") && !file.match?(%r{/(gems|vendor|i18n|node_modules)/})
    end
  end

  task :check => :environment do
    system(yarn_path, "run", "eslint", "-c", config_file, *js_files) || abort
  end

  task :fix => :environment do
    system(yarn_path, "run", "eslint", "-c", config_file, "--fix", *js_files) || abort
  end
end
