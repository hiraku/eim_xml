require "rake/clean"
require "rake/rdoctask"
require "rake/gempackagetask"
require "spec/rake/spectask"

FILES = FileList["**/*"].exclude(/^pkg/, /\.html$/)

task :default => :spec
task :here => "spec:here"

### Document ###
RDOC_DIR = "./html/"
RDOC_OPTS = ["-S", "-w", "3", "-c", "UTF-8", "-m", "README"]
RDOC_OPTS << "-d" if ENV["DOT"]
RDOC_FILES = FileList["lib/**/*.rb"]
RDOC_EXTRAS = FileList["README"]
["", "ja", "en"].each do |l|
	dir = RDOC_DIR.dup
	dir << "#{l}/" unless l.empty?
	Rake::RDocTask.new("rdoc#{":"+l unless l.empty?}") do |rdoc|
		rdoc.title = "Easy IMplemented XML"
		rdoc.options = RDOC_OPTS.dup
		rdoc.options << "-l" << l unless l.empty?
		rdoc.rdoc_dir = dir
		rdoc.rdoc_files.include(RDOC_FILES, RDOC_EXTRAS)
	end
end
task "rdoc:all" => ["rdoc", "rdoc:ja", "rdoc:en"]
task "rerdoc:all" => ["rerdoc", "rerdoc:ja", "rerdoc:en"]


### Publish document ###
task :publish => [:clobber_rdoc, "rdoc:ja", "rdoc:en"] do
	require "rake/contrib/rubyforgepublisher"
	cp "index.html", "html/index.html"
	Rake::RubyForgePublisher.new("eimxml", "hiraku").upload
end

### Spec ###
task :spec => "spec:lump"
SPECS = FileList["spec/**/*_spec.rb"]
namespace :spec do
	def set_spec_opts(spec)
		spec.libs << "lib"
		spec.spec_opts << "-c"
		spec.ruby_opts << "-rtest/unit"
	end


	SPECS.sort{|a,b| File.mtime(a)<=>File.mtime(b)}.reverse.each do |f|
		desc ""
		s = Spec::Rake::SpecTask.new(:apart) do |s|
			s.spec_files = f
			set_spec_opts(s)
		end
	end
	task(:apart).comment = "Run specs separately"

	desc "Run all spec in a lump"
	Spec::Rake::SpecTask.new(:lump) do |s|
		s.spec_files = SPECS
		set_spec_opts(s)
	end

	flg = false
	`grep -Rn spec_here spec`.split(/\n/).each do |l|
		next unless l=~/\A(.*?):(\d+):/
		flg = true
		file = $1
		line = $2.to_i
		Spec::Rake::SpecTask.new(:here) do |s|
			s.spec_files = file
			set_spec_opts(s)
			s.spec_opts << "-l#{line}"
		end
	end
	task :here => :spec unless flg
	task(:here).comment = "Run spec only marked '# spec_here' or all"

	desc "Show all pending spec"
	task :pending do
		grep = `grep -ERn "^[[:space:]]+it([[:space:]]+|$)" *`.split(/\n/)
		puts grep.select{|i| i !~ /\s+do\s*\Z/}
	end
end

Spec::Rake::SpecTask.new(:rcov) do |s|
	s.spec_files = SPECS
	set_spec_opts(s)
	s.rcov = true
	s.rcov_opts << "-x ^#{Regexp.escape(ENV['GEM_HOME'])}"
end

### Build GEM ###
GEM_DIR = "./pkg"
directory GEM_DIR
def build_gem(unstable=false)
	spec = Gem::Specification.new do |spec|
		spec.name = "eimxml"
		spec.rubyforge_project = "eimxml"
		spec.version = ENV["VER"] or raise "Need VER=x.y.z(.?)"
		spec.summary = "Easy IMplemented XML"
		spec.author = "KURODA Hiraku"
		spec.email = "hiraku@hinet.mydns.jp"
		spec.homepage = "http://eimxml.rubyforge.org/"
		spec.files = FILES
		spec.test_files = Dir.glob("test/*.rb")
		spec.has_rdoc = true
		spec.rdoc_options = RDOC_OPTS.dup
		spec.extra_rdoc_files = RDOC_EXTRAS
	end

	spec.version = spec.version.to_s << Time.now.strftime(".%Y.%m%d.%H%M") if unstable
	b = Gem::Builder.new(spec)
	gname = b.build
	mv gname, "#{GEM_DIR}/"
end

desc "Build gem package"
task :gem => GEM_DIR do
	build_gem
end

desc "Build unstable version gem package"
task "gem:unstable" do
	build_gem(true)
end


### Build package ###
package_task = Rake::PackageTask.new("eim_xml",ENV["VER"] || :noversion) do |t|
	t.package_files.include(FILES)
	t.need_tar_gz = true
end
