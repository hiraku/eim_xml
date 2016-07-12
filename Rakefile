require "rdoc/task"
require "rspec/core/rake_task"
require "rubygems/package_task"

VER = "0.0.4"

Rake::RDocTask.new(:rdoc) do |rdoc|
	rdoc.options << "-S"
	rdoc.options << "-w" << "3"
	rdoc.options << "-c" << "UTF-8"
	rdoc.rdoc_files.include("lib/**/*.rb")
	rdoc.title = "Easy IMplemented XML"
	rdoc.main = "README"
	rdoc.rdoc_files.include(FileList["lib/**/*.rb", "README"])
end

gem_spec = Gem::Specification.new do |s|
	s.platform = Gem::Platform::RUBY
	s.files = FileList["Rakefile*", "lib/**/*", "spec/**/*"]

	s.name = "eim_xml"
	s.summary = "Easy IMplemented XML"
	s.author = "KURODA Hiraku"
	s.email = "hirakuro@gmail.com"
	s.homepage = "http://eimxml.rubyforge.org/"
	s.rubyforge_project = "eimxml"
	s.version = VER
end

Gem::PackageTask.new(gem_spec) do |t|
	t.need_tar_gz = true
end

RSpec::Core::RakeTask.new do |s|
	s.rspec_opts ||= []
	s.rspec_opts << "-c"
	s.rspec_opts << "-I" << "./lib"
end

namespace :spec do
	RSpec::Core::RakeTask.new(:coverage) do |s|
		s.rspec_opts ||= []
		s.rspec_opts << "-c"
		s.rspec_opts << "-I" << "./lib"
		s.rspec_opts << "-r" << "./spec/helper_coverage"
	end

	RSpec::Core::RakeTask.new(:profile) do |s|
		s.verbose = false
		s.rspec_opts ||= []
		s.rspec_opts << "-c"
		s.rspec_opts << "-I" << "./lib"
		s.rspec_opts << "-p"
	end
end

task :default => :spec
