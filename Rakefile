load "Rakefile.utirake"
UtiRake.setup do
	rdoc do |t|
		t.title = "Easy IMplemented XML"
		t.main = "README"
		t.rdoc_files.include(FileList["lib/**/*.rb", "README"])
	end

	spec
	rcov

	packages do |s|
		s.name = "eim_xml"
		s.summary = "Easy IMplemented XML"
		s.version = "0.0.2"
		s.author = "KURODA Hiraku"
		s.email = "hiraku@hinet.mydns.jp"
		s.homepage = "http://eimxml.rubyforge.org/"
		s.rubyforge_project = "eimxml"
	end

	publish("eimxml", "hiraku") do
#		cp "index.html", "html/index.html"
	end

	alias_task
end

task :default => :spec
