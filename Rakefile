require "rake/clean"
require "rake/testtask"
require "rake/rdoctask"
require "rake/gempackagetask"

FILES = FileList["**/*"].exclude("pkg", "html")

task :default => :test

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

### Test ###
task :test => "test:apart"
namespace :test do
	FileList["test/*_test.rb"].sort{|a,b| File.mtime(a)<=>File.mtime(b)}.reverse.each do |i|
		Rake::TestTask.new(:apart) do |t|
			t.test_files = [i]
		end
	end
	task(:apart).comment = "Run tests separately"

	Rake::TestTask.new(:lump) do |t|
		t.test_files = FileList["test/*_test.rb"]
	end
	task(:lump).comment = "Run all tests in a lump"
end

### Build GEM ###
GEM_DIR = "./pkg"
directory GEM_DIR
def build_gem(unstable=false)
	spec = Gem::Specification.new do |spec|
		spec.name = "eimxml"
		spec.rubyforge_project = "eimxml"
		spec.version = "0.0.1"
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
