require "eim_xml"

class << Object.new
	include EimXML

	describe PCString do
		it ".encode" do
			PCString.encode("<>\"'&").should == "&lt;&gt;&quot;&apos;&amp;"
			PCString.encode("&test;").should == "&amp;test;"
			PCString.encode("&amp;").should == "&amp;amp;"
		end

		it ".new" do
			PCString.new("&").encoded_string.should == "&amp;"
			PCString.new("&", true).encoded_string.should == "&"
		end

		it "#==" do
			p1 = PCString.new("str")
			p2 = PCString.new("str")
			p2.should == p1

			"str".should_not == p1
		end

		it "#to_xml" do
			PCString.new("&amp;").to_xml.should == "&amp;amp;"
		end
	end

	describe Element do
		class Dummy < Element
			def chgname(name)
				self.name = name
			end
		end

		it "#name" do
			e = Element.new("el")
			e.name.should == :el
			lambda{e.name="changed"}.should raise_error(NoMethodError)

			d = Dummy.new("el1")
			d.name.should == :el1
			d.chgname(:el2)
			d.name.should == :el2
			d.chgname("el3")
			d.name.should == :el3
		end

		it "#atributes" do
			e = Element.new("el", {"a1"=>"v1", "a2"=>"v2", "a3"=>nil})
			e.name.should == :el
			e.attributes.should == {:a1=>"v1", :a2=>"v2", :a3=>nil}
		end

		it "#[]" do
			e = Element.new(:el, :attr=>"value")
			e << "test"
			e[:attr].should == "value"
			e[0].should == "test"
		end

		it "#add_attribute" do
			e = Element.new("el")
			e.add_attribute("key_str", "value1")
			e.add_attribute(:key_sym, "value2")
			e.attributes.should == {:key_str=>"value1", :key_sym=>"value2"}
			e.add_attribute(:nil, nil)
			e.attributes.should == {:key_str=>"value1", :key_sym=>"value2", :nil=>nil}
		end

		it "#del_attribute" do
			e = Element.new("el", {:a1=>"v1", :a2=>"v2"})
			e.del_attribute("a1")
			e.attributes.should == {:a2=>"v2"}
			e.del_attribute(:a2)
			e.attributes.should == {}
		end

		it "#contents" do
			sub = Element.new("sub")
			e = Element.new("el") << "String1" << "String2" << sub
			e.contents.should == ["String1", "String2", sub]
		end

		it "#add" do
			e = Element.new("el").add(Element.new("sub"))
			e.should be_kind_of(Element)
			e.name.should == :el

			e = Element.new("el")
			e.add(Element.new("sub1"))
			e.add([Element.new("sub2").add("text"), "string"])
			e.contents.should == [Element.new("sub1"), Element.new("sub2").add("text"), "string"]

			e = Element.new("el")
			e.add(nil)
			e.contents.size.should == 0

			e = Element.new("el").add(:symbol)
			e.contents.should == [:symbol]
			e.to_xml.should == "<el>symbol</el>"

			e = Element.new("super") << Element.new("sub")
			e.name.should == :super
			e.contents.should == [Element.new("sub")]
		end

		it "#to_xml with indent" do
			e = Element.new("el")
			s = String.new

			e.to_xml(s).object_id.should == s.object_id
			s.should == "<el />"

			e = Element.new("super")
			e << Element.new("sub")
			e.to_xml.should == "<super><sub /></super>"
			e << Element.new("sub2")
			e.to_xml.should == "<super>\n <sub />\n <sub2 />\n</super>"
			e.to_xml("", 1).should == "<super>\n  <sub />\n  <sub2 />\n </super>"

			s = Element.new("supersuper")
			s << e
			s.to_xml.should == "<supersuper><super>\n <sub />\n <sub2 />\n</super></supersuper>"

			e = Element.new("el") << "str"
			s = Element.new("sub")
			s << "inside"
			e << s
			e.to_xml.should == "<el>\n str\n <sub>inside</sub>\n</el>"

			e = Element.new("el")
			e.attributes["a1"] = "v1"
			e.attributes["a2"] = "'\"<>&"
			s = e.to_xml
			s.should =~ /\A<el ([^>]*) \/>\z/
			s.should =~ /a1='v1'/
			s.should =~ /a2='&apos;&quot;&lt;&gt;&amp;'/

			e = Element.new("el", {"a1"=>nil})
			e.to_xml.should == "<el a1='a1' />"
		end

		it "#to_xml" do
			el = Element.new("el")
			ex = "<el />"
			el.to_xml.should == ex

			s = ""
			r = el.to_xml(s)
			r.should == ex
			r.object_id.should == s.object_id
		end

		it "encode special characters" do
			e = Element.new("el") << "&\"'<>"
			e << PCString.new("&\"'<>", true)
			e.attributes["key"] = PCString.new("&\"'<>", true)
			e.to_s.should == %[<el key='&\"'<>'>\n &amp;&quot;&apos;&lt;&gt;\n &\"'<>\n</el>]
		end

		it "#dup" do
			e = Element.new("el")
			e.attributes["key"] = "value"
			e << "String"
			e << "Freeze".freeze
			s = Element.new("sub")
			s.attributes["subkey"] = "subvalue"
			e << s
			f = e.dup

			f.attributes.object_id.should == e.attributes.object_id
			f.contents.object_id.should == e.contents.object_id

			f.to_s.should == e.to_s

			e = Element.new("el")
			e.hold_space
			f = e.dup
			f.should be_hold_space
		end

		it "#clone" do
			e = Element.new("el")
			e.attributes["key"] = "value"
			e << "String"
			e << "Freeze".freeze
			s = Element.new("sub")
			s.attributes["subkey"] = "subvalue"
			e << s
			f = e.clone

			f.attributes.object_id.should == e.attributes.object_id
			f.contents.object_id.should == e.contents.object_id

			f.to_s.should == e.to_s

			e = Element.new("el")
			e.hold_space
			f = e.clone
			f.should be_hold_space
		end

		it "#hold_space" do
			e = Element.new("el") << "Line1" << "Line2"
			s = Element.new("sub") << "Sub1" << "Sub2"
			ss = Element.new("subsub") << "ss1" << "ss2"
			s << ss
			e << s
			e.hold_space
			e.to_s.should == "<el>Line1Line2<sub>Sub1Sub2<subsub>ss1ss2</subsub></sub></el>"

			e.unhold_space
			e.to_s.should == "<el>\n Line1\n Line2\n <sub>\n  Sub1\n  Sub2\n  <subsub>\n   ss1\n   ss2\n  </subsub>\n </sub>\n</el>"

			e = Element.new("e")
			e.hold_space.object_id.should == e.object_id
			e.unhold_space.object_id.should == e.object_id
		end

		it "#==" do
			e1 = Element.new("el")
			e1.attributes["key"] = "value"
			s = Element.new("sub")
			s << "String"
			e1 << s
			e2 = e1.dup
			e2.should == e1

			e3 = Element.new("e")
			e3.attributes["key"] = "value"
			s = Element.new("sub")
			s << "String"
			e3 << s
			e3.should_not == e1

			e3 = Element.new("e")
			e3.attributes["k"] = "value"
			s = Element.new("sub")
			s << "String"
			e3 << s
			e3.should_not == e1

			e3 = Element.new("e")
			e3.attributes["key"] = "v"
			s = Element.new("sub")
			s << "String"
			e3 << s
			e3.should_not == e1

			e3 = Element.new("e")
			e3.attributes["key"] = "value"
			s = Element.new("sub")
			s << "S"
			e3 << s
			e3.should_not == e1

			e3 = Element.new("e")
			e3.attributes["key"] = "value"
			s = Element.new("s")
			s << "String"
			e3 << s
			e3.should_not == e1

			"string".should_not == e1
		end

		it ".new with block" do
			base = nil
			e = Element.new("base") do |b|
				b["attr"]="value"
				b << Element.new("sub")
				base = b
			end
			base.object_id.should == e.object_id

			e2 = Element.new("base", "attr"=>"value")
			e2 << Element.new("sub")
			e2.should == e

			e = Element.new("base") do |e|
				e <<= Element.new("sub1") do |e|
					e <<= Element.new("sub12")
				end
				e <<= Element.new("sub2")
			end
			base = Element.new("base")
			sub1 = Element.new("sub1")
			sub1 << Element.new("sub12")
			sub2 = Element.new("sub2")
			base << sub1  << sub2
			e.should == base
		end

		it "#to_s should return same string whenever name of element or attribute given with string or symbol" do
			sym = Element.new(:tag, :attr=>"value")
			str = Element.new("tag", "attr"=>"value")

			str.to_s.should == sym.to_s
			str.should == sym
		end

		it "#match" do
			e = Element.new(:tag, :attr=>"value")
			e.match(:tag).should be_true
			e.match(:tag, :attr=>"value").should be_true
			e.match(:t).should be_false
			e.match(:tag, :attr2=>"value").should be_false
			e.match(:tag, :attr=>"value2").should be_false
			e.match(:tag, :attr=>/val/).should be_true

			e.match(Element.new(:tag)).should be_true
			e.match(Element.new(:tag, :attr=>"value")).should be_true
			e.match(Element.new(:tag, :attr=>/alu/)).should be_true
			e.match(Element.new(:t)).should be_false
			e.match(Element.new(:tag, :attr2=>"value")).should be_false
			e.match(Element.new(:tag, :attr=>"value2")).should be_false
			e.match(Element.new(:tag, :attr=>/aul/)).should be_false

			(!!e.match(/ag/)).should be_true
			(!!e.match(/elem/)).should be_false

			e.match(Element).should be_true
			e.match(Dummy).should be_false
			e.match(String).should be_false

			e = Element.new(:element)
			e << Element.new(:sub)
			e << "text"
			e.match(DSL.element(:element){element(:sub)}).should be_true
			e.match(DSL.element(:element){element(:other)}).should be_false
			e.match(DSL.element(:element){add("text")}).should be_true
			e.match(DSL.element(:element){add("other")}).should be_false
			e.match(DSL.element(:element){add(/ex/)}).should be_true
			e.match(DSL.element(:element){add(/th/)}).should be_false
			e.match(DSL.element(:element){add(/sub/)}).should be_false
		end

		it "#=~" do
			e = Element.new(:tag, :attr=>"value", :a2=>"v2")
			e.should =~ :tag
			e.should =~ Element.new(:tag)
			e.should =~ Element.new(:tag, :a2=>"v2")
			e.should =~ Element.new(:tag, :attr=>/alu/)

			e.should_not =~ :t
			e.should_not =~ Element.new(:t)
			e.should_not =~ Element.new(:tag, :attr=>/aul/)
		end

		%w[has? has_element? include?].each do |method|
			it "##{method}" do
				e = Element.new(:base) do |b|
					b <<= Element.new(:sub) do |s|
						s <<= Element.new(:deep) do |d|
							d << "text"
						end
					end
					b <<= Element.new(:sub, :attr=>"value")
				end

				e.send(method, :sub).should be_true
				e.send(method, :sub, :attr=>"value").should be_true
				e.send(method, :sub, :attr=>"value", :attr2=>"").should be_false
				e.send(method, :deep).should be_true

				e.send(method, String).should be_true
			end
		end

		it "#find" do
			s1 = Element.new(:sub)
			d = Element.new(:deep)
			d << "3rd"
			s1 << "2nd" << d
			s2 = Element.new(:sub, :attr=>"value")
			e = Element.new(:base)
			e << "1st" << s1 << s2

			e.find(:deep).should be_kind_of(Element)
			e.find(:deep).name.should == :found
			e.find(:deep).contents.should == [d]
			e.find(:sub).contents.should == [s1, s2]
			e.find(//).contents.should == [e, s1, d, s2]
			e.find(:sub, :attr=>"value").contents.should == [s2]
			e.find(String).contents.should == ["1st", "2nd", "3rd"]
		end
	end

	describe SymbolKeyHash do
		it "#new" do
			s = SymbolKeyHash.new({"key1"=>"value1", :key2=>"value2"})
			s.should == {:key1=>"value1", :key2=>"value2"}
		end

		it "#update" do
			h = {"key"=>"value"}
			s = SymbolKeyHash.new
			s.update(h)
			s.should == {:key=>"value"}

			s2 = SymbolKeyHash.new
			s2.update(s)
			s2.should == s
		end

		it "#merge" do
			s = SymbolKeyHash.new
			s2 = s.merge({"key"=>"value"})
			s.should == {}
			s2.should == {:key=>"value"}
		end

		it "#merge!" do
			s = SymbolKeyHash.new
			s2 = s.merge!({"key"=>"value"})
			h = {:key=>"value"}
			s.should == h
			s2.should == h
		end

		it "#store" do
			s = SymbolKeyHash.new
			s.store(:sym1, "value1")
			s.store("str1", "value2")
			s[:sym2] = "value3"
			s["str2"] = "value4"

			s.should == {:sym1=>"value1", :str1=>"value2", :sym2=>"value3", :str2=>"value4"}
		end
	end

	describe DSL do
		it "scope is in instance of DSL" do
			outer = inner = nil
			e3 = e2 = nil
			block_executed = false
			e = DSL.element(:out, :k1=>"v1") do
				outer = self
				e2 = element(:in, :k2=>"v2") do
					block_executed = true
					inner = self
					e3 = element(:deep)
				end
			end

			block_executed.should == true
			outer.should be_kind_of(DSL)
			inner.should be_kind_of(DSL)
			outer.object_id.should == inner.object_id

			e.name.should == :out
			e[:k1].should == "v1"
			e[0].name.should == :in
			e[0][:k2].should == "v2"
			e[0][0].name.should == :deep
			e2.object_id.should == e[0].object_id
			e3.object_id.should == e[0][0].object_id
		end
	end

	describe "Subclass of BaseDSL" do
		class DSL1 < BaseDSL
			register([EimXML::Element, "call"])
			register(Hash)
			register(String, Array, Object)
		end

		it "register" do
			lambda{DSL.call(:dummy)}.should raise_error(NoMethodError)
			lambda{BaseDSL.call(:dummy)}.should raise_error(NoMethodError)
			lambda{DSL1.element(:dummy)}.should raise_error(NoMethodError)
			DSL1.call(:dummy).should be_kind_of(Element)
			DSL1.hash.should be_kind_of(Hash)
			DSL1.string.should be_kind_of(String)
			DSL1.array.should be_kind_of(Array)
			DSL1.object.should be_kind_of(Object)
		end
	end

	describe OpenDSL do
		it "scope of block is one of outside" do
			@scope_checker_variable = 1
			block_executed = false
			d = OpenDSL.new do |d|
				block_executed = true
				d.should be_kind_of(OpenDSL)
				d.container.should be_nil
				d.element(:base, :key1=>"v1") do
					@scope_checker_variable.should == 1
					self.should_not be_kind_of(Element)
					d.container.should be_kind_of(Element)
					d.container.should == Element.new(:base, :key1=>"v1")
					d.element(:sub, :key2=>"v2") do
						d.container.should be_kind_of(Element)
						d.container.should == Element.new(:sub, :key2=>"v2")
					end
					d.element(:sub2).should == Element.new(:sub2)
				end
			end
			block_executed.should be_true
		end

		it "DSL methods return element" do
			d = OpenDSL.new
			d.container.should be_nil
			r = d.element(:base, :key1=>"v1") do
				d.element(:sub, :key2=>"v2")
			end
			r.should == DSL.element(:base, :key1=>"v1") do
				element(:sub, :key2=>"v2")
			end
		end

		it "DSL method's block given instance of OpenDSL" do
			e = OpenDSL.new.element(:base) do |d|
				d.should be_kind_of(OpenDSL)
				d.container.name.should == :base
				d.element(:sub) do |d2|
					d2.object_id.should == d.object_id
				end
			end

			e.should == DSL.element(:base) do
				element(:sub)
			end
		end

		it "ensure reset container when error raised" do
			OpenDSL.new do |d|
				begin
					d.element(:base) do
						begin
							d.element(:sub) do
								raise "OK"
							end
						rescue RuntimeError => e
							raise unless e.message=="OK"
							d.container.name.should == :base
							raise
						end
					end
				rescue RuntimeError => e
					raise unless e.message=="OK"
					d.container.should == nil
				end
			end
		end

		it "respond to add" do
			r = OpenDSL.new.element(:base) do |d|
				d.add "text"
				d.element(:sub) do
					s = Element.new(:sub)
					s.add("sub text")
					d.add("sub text").should == s
				end
			end

			r.should == DSL.element(:base) do
				add "text"
				element(:sub) do
					add "sub text"
				end
			end
		end

		it "respond to <<" do
			r = OpenDSL.new.element(:base) do |d|
				b = Element.new(:base)
				b << "text" << "next"
				(d << "text" << "next").should == b
			end
			r.should == DSL.element(:base) do
				add "text"
				add "next"
			end
		end

		it "can call directly element method" do
			r = OpenDSL.element(:base) do |d|
				d.element(:sub)
				d.element(:sub2)
			end
			r.should == DSL.element(:base) do
				element(:sub)
				element(:sub2)
			end
		end
	end
end
