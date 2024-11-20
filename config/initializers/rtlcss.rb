require "rtlcss"

class RtlcssSCSSProcessor < SassC::Rails::ScssTemplate
  def self.call(input)
    output = super
    data = Rtlcss.flip_css(output[:data])
    output.delete(:map)
    output.merge(:data => data)
  end
end

Rails.application.config.assets.configure do |env|
  env.register_mime_type "text/rtlcss+scss", :extensions => [".rtlcss.scss"]
  env.register_transformer "text/rtlcss+scss", "text/css", RtlcssSCSSProcessor
  env.register_preprocessor "text/rtlcss+scss", Sprockets::DirectiveProcessor.new(:comments => ["//", ["/*", "*/"]])
end
