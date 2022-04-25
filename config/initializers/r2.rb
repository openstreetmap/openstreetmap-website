require "r2"

class R2ScssProcessor < SassC::Rails::ScssTemplate
  def self.call(input)
    output = super(input)
    data = R2.r2(output[:data])
    output.delete(:map)
    output.merge(:data => data)
  end
end

Rails.application.config.assets.configure do |env|
  env.register_mime_type "text/r2+scss", :extensions => [".r2.scss"]
  env.register_transformer "text/r2+scss", "text/css", R2ScssProcessor
  env.register_preprocessor "text/r2+scss", Sprockets::DirectiveProcessor.new(:comments => ["//", ["/*", "*/"]])
end
