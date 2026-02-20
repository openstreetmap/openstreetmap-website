# frozen_string_literal: true

namespace :oauth do
  desc "Register the built-in apps with specified user as owner; append necessary changes to settings file"
  task :register_apps, [:display_name] => :environment do |task, args|
    Oauth::Util.register_apps(
      args.display_name,
      :generated_by => "#{task} rake task"
    )
  end
end
