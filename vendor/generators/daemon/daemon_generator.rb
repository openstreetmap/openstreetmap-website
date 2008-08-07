class DaemonGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.directory "lib/daemons"
      m.file "daemons", "script/daemons", :chmod => 0755
      m.template "script.rb", "lib/daemons/#{file_name}.rb", :chmod => 0755
      m.template "script_ctl", "lib/daemons/#{file_name}_ctl", :chmod => 0755
      m.file "daemons.yml", "config/daemons.yml"
    end
  end
end