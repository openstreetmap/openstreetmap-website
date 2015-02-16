class R2Template < Tilt::Template
  self.default_mime_type = 'text/css'

  def self.engine_initialized?
    defined? ::R2
  end

  def initialize_engine
    require_template_library "r2"
  end

  def prepare
    @output = R2.r2(data)
  end

  def evaluate(_scope, _locals, &_block)
    @output
  end
end

Rails.application.assets.register_engine ".r2", R2Template
