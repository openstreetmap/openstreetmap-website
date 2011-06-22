# Rakefile for Rack.  -*-ruby-*-
require 'rake/rdoctask'
require 'rake/testtask'
require 'spec/rake/spectask'


desc "Run all the tests"
task :default => [:spec]

desc "Do predistribution stuff"
task :predist => [:changelog, :rdoc]


desc "Make an archive as .tar.gz"
task :dist => [:fulltest, :predist] do
  sh "git archive --format=tar --prefix=#{release}/ HEAD^{tree} >#{release}.tar"
  sh "pax -waf #{release}.tar -s ':^:#{release}/:' RDOX SPEC ChangeLog doc"
  sh "gzip -f -9 #{release}.tar"
end

# Helper to retrieve the "revision number" of the git tree.
def git_tree_version
  #if File.directory?(".git")
  #  @tree_version ||= `git describe`.strip.sub('-', '.')
  #  @tree_version << ".0"  unless @tree_version.count('.') == 2
  #else
    $: << "lib"
    require 'rots'
    @tree_version = Rots.release
  #end
  @tree_version
end

def gem_version
  git_tree_version.gsub(/-.*/, '')
end

def release
  "ruby-openid-tester-#{git_tree_version}"
end

def manifest
  `git ls-files`.split("\n")
end

desc "Generate a ChangeLog"
task :changelog do
  File.open("ChangeLog", "w") do |out|
    `git log -z`.split("\0").map do |chunk|
      author = chunk[/Author: (.*)/, 1].strip
      date   = chunk[/Date: (.*)/, 1].strip
      desc, detail = $'.strip.split("\n", 2)
      detail ||= ""
      detail.rstrip!
      out.puts "#{date}  #{author}"
      out.puts "  * #{desc.strip}"
      out.puts detail  unless detail.empty?
      out.puts
    end
  end
end


begin
  require 'rubygems'

  require 'rake'
  require 'rake/clean'
  require 'rake/packagetask'
  require 'rake/gempackagetask'
  require 'fileutils'
rescue LoadError
  # Too bad.
else
  spec = Gem::Specification.new do |s|
    s.name            = "rots"
    s.version         = gem_version
    s.platform        = Gem::Platform::RUBY
    s.summary         = "an OpenID server for making tests of OpenID clients implementations"

    s.description = <<-EOF
Ruby OpenID Test Server (ROST) provides a basic OpenID server made in top of the Rack gem.
With this small server, you can make dummy OpenID request for testing purposes,
the success of the response will depend on a parameter given on the url of the authentication request.
    EOF

    s.files           = manifest
    s.bindir          = 'bin'
    s.executables     << 'rots'
    s.require_path    = 'lib'
    s.has_rdoc        = true
    s.extra_rdoc_files = ['README']
    s.test_files      = Dir['spec/*_spec.rb']

    s.author          = 'Roman Gonzalez'
    s.email           = 'romanandreg@gmail.com'
    s.homepage        = 'http://github.com/roman'
    s.rubyforge_project = 'rots'

    s.add_development_dependency 'rspec'
    s.add_development_dependency 'rack'
    s.add_development_dependency 'ruby-openid', '~> 2.0.0'
  end

  Rake::GemPackageTask.new(spec) do |p|
    p.gem_spec = spec
    p.need_tar = false
    p.need_zip = false
  end
end

Spec::Rake::SpecTask.new do |t|
end

desc "Generate RDoc documentation"
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.options << '--line-numbers' << '--inline-source' <<
    '--main' << 'README' <<
    '--title' << 'ROTS Documentation' <<
    '--charset' << 'utf-8'
  rdoc.rdoc_dir = "doc"
  rdoc.rdoc_files.include 'README'
  rdoc.rdoc_files.include('lib/ruby_openid_test_server.rb')
  rdoc.rdoc_files.include('lib/ruby_openid_test_server/*.rb')
end
