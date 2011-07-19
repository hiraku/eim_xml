load "Rakefile.utirake"
VER = "0.0.4"

UtiRake.setup do
	rdoc do |t|
		t.title = "Easy IMplemented XML"
		t.main = "README"
		t.rdoc_files.include(FileList["lib/**/*.rb", "README"])
	end

	gemspec do |s|
		s.name = "eim_xml"
		s.summary = "Easy IMplemented XML"
		s.author = "KURODA Hiraku"
		s.email = "hiraku@hinet.mydns.jp"
		s.homepage = "http://eimxml.rubyforge.org/"
		s.rubyforge_project = "eimxml"
		s.version = VER
	end

	publish("eimxml", "hiraku")

	alias_task
end

task :default => :spec
