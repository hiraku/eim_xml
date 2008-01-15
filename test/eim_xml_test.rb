# Test for eim_xml.rb
#
# Copyright (C) 2006, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.

require "test/unit"
require "eim_xml"
require "spec"

class PCStringTest < Test::Unit::TestCase
	include EimXML

	def test_encode
		assert_equal("&lt;&gt;&quot;&apos;&amp;", PCString.encode("<>\"'&"))
		assert_equal("&amp;test;", PCString.encode("&test;"))
		assert_equal("&amp;amp;", PCString.encode("&amp;"))
	end

	def test_new
		assert_equal("&amp;", PCString.new("&").encoded_string)
		assert_equal("&", PCString.new("&", true).encoded_string)
	end

	def test_equal
		p1 = PCString.new("str")
		p2 = PCString.new("str")
		assert_equal(p1, p2)

		assert_not_equal(p1, "str")
	end

	def test_to_xml
		assert_equal("&amp;amp;", PCString.new("&amp;").to_xml)
	end
end

class ElementTest < Test::Unit::TestCase
	include EimXML

	class Dummy < Element
		def chgname(name)
			self.name = name
		end
	end

	def test_name
		e = Element.new("el")
		assert_equal(:el, e.name)
		assert_raises(NoMethodError){e.name="changed"}

		d = Dummy.new("el1")
		assert_equal(:el1, d.name)
		d.chgname(:el2)
		assert_equal(:el2, d.name)
		d.chgname("el3")
		assert_equal(:el3, d.name)
	end

	def test_attributes
		e = Element.new("el", {"a1"=>"v1", "a2"=>"v2", "a3"=>nil})
		assert_equal(:el, e.name)
		assert_equal({:a1=>"v1", :a2=>"v2", :a3=>nil}, e.attributes)
	end

	def test_bracket
		e = Element.new(:el, :attr=>"value")
		e << "test"
		assert_equal("value", e[:attr])
		assert_equal("test", e[0])
	end

	def test_add_attribute
		e = Element.new("el")
		e.add_attribute("key_str", "value1")
		e.add_attribute(:key_sym, "value2")
		assert_equal({:key_str=>"value1", :key_sym=>"value2"}, e.attributes)
		e.add_attribute(:nil, nil)
		assert_equal({:key_str=>"value1", :key_sym=>"value2", :nil=>nil}, e.attributes)
	end

	def test_del_attribute
		e = Element.new("el", {:a1=>"v1", :a2=>"v2"})
		e.del_attribute("a1")
		assert_equal({:a2=>"v2"}, e.attributes)
		e.del_attribute(:a2)
		assert_equal({}, e.attributes)
	end

	def test_contents
		sub = Element.new("sub")
		e = Element.new("el") << "String1" << "String2" << sub
		assert_equal(["String1", "String2", sub], e.contents)
	end

	def test_add
		e = Element.new("el").add(Element.new("sub"))
		assert_instance_of(Element, e, "add Element")
		assert_equal(:el, e.name)

		e = Element.new("el")
		e.add(Element.new("sub1"))
		e.add([Element.new("sub2").add("text"), "string"])
		assert_equal([Element.new("sub1"), Element.new("sub2").add("text"), "string"], e.contents, "add Array")

		e = Element.new("el")
		e.add(nil)
		assert_equal(0, e.contents.size, "add nil")

		e = Element.new("el").add(:symbol)
		assert_equal([:symbol], e.contents, "add anything(which has to_s)")
		assert_equal("<el>symbol</el>", e.to_xml)

		e = Element.new("super") << Element.new("sub")
		assert_equal(:super, e.name)
		assert_equal([Element.new("sub")], e.contents)
	end

	def test_to_xml_with_indent
		e = Element.new("el")
		s = String.new
		assert_equal(s.object_id, e.to_xml_with_indent(s).object_id)
		assert_equal("<el />", s)

		e = Element.new("super")
		e << Element.new("sub")
		assert_equal("<super><sub /></super>", e.to_xml_with_indent)
		e << Element.new("sub2")
		assert_equal("<super>\n <sub />\n <sub2 />\n</super>", e.to_xml_with_indent)
		assert_equal(" <super>\n  <sub />\n  <sub2 />\n </super>", e.to_xml_with_indent("", 1))
		assert_equal("<super>\n  <sub />\n  <sub2 />\n </super>", e.to_xml_with_indent("", 1, false))

		s = Element.new("supersuper")
		s << e
		assert_equal("<supersuper><super>\n <sub />\n <sub2 />\n</super></supersuper>", s.to_xml_with_indent)

		e = Element.new("el") << "str"
		s = Element.new("sub")
		s << "inside"
		e << s
		assert_equal("<el>\n str\n <sub>inside</sub>\n</el>", e.to_xml_with_indent)

		e = Element.new("el")
		e.attributes["a1"] = "v1"
		e.attributes["a2"] = "'\"<>&"
		s = e.to_xml_with_indent
		assert_match(/\A<el ([^>]*) \/>\z/, s)
		assert_match(/a1='v1'/, s)
		assert_match(/a2='&apos;&quot;&lt;&gt;&amp;'/, s)

		e = Element.new("el", {"a1"=>nil})
		assert_equal("<el a1='a1' />", e.to_xml_with_indent)
	end

	def test_to_xml
		el = Element.new("el")
		ex = "<el />"
		assert_equal(ex, el.to_xml)

		s = ""
		r = el.to_xml(s)
		assert_equal(ex, r)
		assert_equal(s.object_id, r.object_id)
	end

	def test_spcial_string
		e = Element.new("el") << "&\"'<>"
		e << PCString.new("&\"'<>", true)
		e.attributes["key"] = PCString.new("&\"'<>", true)
		assert_equal(%[<el key='&\"'<>'>\n &amp;&quot;&apos;&lt;&gt;\n &\"'<>\n</el>], e.to_s)
	end

	def test_dup
		e = Element.new("el")
		e.attributes["key"] = "value"
		e << "String"
		e << "Freeze".freeze
		s = Element.new("sub")
		s.attributes["subkey"] = "subvalue"
		e << s
		f = e.dup

		assert_equal(e.attributes.object_id, f.attributes.object_id)
		assert_equal(e.contents.object_id, f.contents.object_id)

		assert_equal(e.to_s, f.to_s)

		e = Element.new("el")
		e.hold_space
		f = e.dup
		assert(f.hold_space?)
	end

	def test_clone
		e = Element.new("el")
		e.attributes["key"] = "value"
		e << "String"
		e << "Freeze".freeze
		s = Element.new("sub")
		s.attributes["subkey"] = "subvalue"
		e << s
		f = e.clone

		assert_equal(e.attributes.object_id, f.attributes.object_id)
		assert_equal(e.contents.object_id, f.contents.object_id)

		assert_equal(e.to_s, f.to_s)

		e = Element.new("el")
		e.hold_space
		f = e.clone
		assert(f.hold_space?)
	end

	def test_hold_space
		e = Element.new("el") << "Line1" << "Line2"
		s = Element.new("sub") << "Sub1" << "Sub2"
		ss = Element.new("subsub") << "ss1" << "ss2"
		s << ss
		e << s
		e.hold_space
		assert_equal("<el>Line1Line2<sub>Sub1Sub2<subsub>ss1ss2</subsub></sub></el>", e.to_s)

		e.unhold_space
		assert_equal("<el>\n Line1\n Line2\n <sub>\n  Sub1\n  Sub2\n  <subsub>\n   ss1\n   ss2\n  </subsub>\n </sub>\n</el>", e.to_s)

		e = Element.new("e")
		assert_equal(e.object_id, e.hold_space.object_id)
		assert_equal(e.object_id, e.unhold_space.object_id)
	end

	def test_equal
		e1 = Element.new("el")
		e1.attributes["key"] = "value"
		s = Element.new("sub")
		s << "String"
		e1 << s
		e2 = e1.dup
		assert_equal(e1, e2)

		e3 = Element.new("e")
		e3.attributes["key"] = "value"
		s = Element.new("sub")
		s << "String"
		e3 << s
		assert_not_equal(e1, e3)

		e3 = Element.new("e")
		e3.attributes["k"] = "value"
		s = Element.new("sub")
		s << "String"
		e3 << s
		assert_not_equal(e1, e3)

		e3 = Element.new("e")
		e3.attributes["key"] = "v"
		s = Element.new("sub")
		s << "String"
		e3 << s
		assert_not_equal(e1, e3)

		e3 = Element.new("e")
		e3.attributes["key"] = "value"
		s = Element.new("sub")
		s << "S"
		e3 << s
		assert_not_equal(e1, e3)

		e3 = Element.new("e")
		e3.attributes["key"] = "value"
		s = Element.new("s")
		s << "String"
		e3 << s
		assert_not_equal(e1, e3)

		assert_not_equal(e1, "string")
	end

	def test_new_with_block
		base = nil
		e = Element.new("base") do |b|
			b["attr"]="value"
			b << Element.new("sub")
			base = b
		end
		assert_same(e, base)
		e2 = Element.new("base", "attr"=>"value")
		e2 << Element.new("sub")
		assert_equal(e, e2)

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
		assert_equal(base, e)
	end

	def test_symbol_string_compatible
		sym = Element.new(:tag, :attr=>"value")
		str = Element.new("tag", "attr"=>"value")

		assert_equal(sym.to_s, str.to_s)
		assert_equal(sym, str)
	end

	def test_match
		e = Element.new(:tag, :attr=>"value")
		assert(e.match?(:tag))
		assert(e.match?(:tag, :attr=>"value"))
		assert(! e.match?(:t))
		assert(! e.match?(:tag, :attr2=>"value"))
		assert(! e.match?(:tag, :attr=>"value2"))

		assert(e.match?(Element.new(:tag)))
		assert(e.match?(Element.new(:tag, :attr=>"value")))
		assert(! e.match?(Element.new(:t)))
		assert(! e.match?(Element.new(:tag, :attr2=>"value")))
		assert(! e.match?(Element.new(:tag, :attr=>"value2")))

		assert(e.match?(/ag/))
		assert(e.match?(/ag/, /tt/=>/al/))
		assert(! e.match?(/elem/))
		assert(! e.match?(/tag/, /attr2/=>/val/))
		assert(! e.match?(/tag/, /attr/=>/v2/))

		assert(e.match?(:tag, :attr=>/val/))
		assert(e.match?(/t/, /at/=>"value"))

		e = Element.new(:tag, :attr1=>"value", :attr2=>"test")
		assert(e.match?(:tag, /attr/=>"value"))
		assert(e.match?(:tag, /attr/=>/t/))

		assert(e.match?(Element))
		assert(!e.match?(Dummy))
		assert(!e.match?(String))

		e1 = Element.new(:tag, :attr=>:value)
		e2 = Element.new(:tag, :attr=>"value")
		assert(e1.match?(e2))
		assert(e2.match?(e1))
	end

	def test_match_by_array
		e = Element.new(:tag, :attr=>"value", :a2=>"v2")
		assert(e.match?([:tag]))
		assert(e.match?([:tag, {:attr=>"value"}]))
		assert(e.match?([:tag, {:attr=>"value", :a2=>"v2"}]))
		assert(e.match?([/tag/, {/a/=>/v/}]))
	end

	def test_match_operator
		e = Element.new(:tag, :attr=>"value", :a2=>"v2")
		assert_match(:tag, e)
		assert_match(Element.new(:tag), e)
		assert_match([:tag], e)
		assert_match([:tag, {:attr=>"value"}], e)
		assert_match(Element.new(:tag, :a2=>"v2"), e)
		assert_match([/t/, {/a/=>/v/}], e)

		assert(e !~ :t)
		assert(e !~ Element.new(:t))
		assert(e !~ [:t])
		assert(e !~ [:tag, {:a=>"v"}])
		assert(e !~ Element.new(:tag, :a=>"v"))
	end

	def test_has
		e = Element.new(:base) do |b|
			b <<= Element.new(:sub) do |s|
				s <<= Element.new(:deep) do |d|
					d << "text"
				end
			end
			b <<= Element.new(:sub, :attr=>"value")
		end

		assert(e.has?(:base))
		assert(e.has?(:sub))
		assert(e.has?(:sub, :attr=>"value"))
		assert(!e.has?(:sub, :attr=>"value", :attr2=>""))
		assert(e.has?(:deep))
		assert(! e.has?(:deep, {}, false))

		assert(e.has?(String))

		e = DSL.element(:base) do
			element(:sub, :sym=>:v1, "string"=>"v2")
		end
		assert(e.has?(Element.new(:sub, :sym=>"v1")))
		assert(e.has?(Element.new(:sub, "sym"=>"v1")))
		assert(e.has?(Element.new(:sub, "string"=>:v2)))
		assert(e.has?(Element.new(:sub, :string=>:v2)))
	end

	def test_find
		s1 = Element.new(:sub)
		d = Element.new(:deep)
		d << "3rd"
		s1 << "2nd" << d
		s2 = Element.new(:sub, :attr=>"value")
		e = Element.new(:base)
		e << "1st" << s1 << s2

		assert_equal([d], e.find(:deep))
		assert_equal([s1, s2], e.find(:sub))
		assert_equal([e, s1, d, s2], e.find(//))

		assert_equal(["1st", "2nd", "3rd"], e.find(String))
	end
end

class SymbolKeyHashTest < Test::Unit::TestCase
	SKH = EimXML::SymbolKeyHash

	def test_new
		s = SKH.new({"key1"=>"value1", :key2=>"value2"})
		assert_equal({:key1=>"value1", :key2=>"value2"}, s)
	end

	def test_update
		h = {"key"=>"value"}
		s = SKH.new
		s.update(h)
		assert_equal({:key=>"value"}, s)

		s2 = SKH.new
		s2.update(s)
		assert_equal(s, s2)
	end

	def test_merge
		s = SKH.new
		s2 = s.merge({"key"=>"value"})
		assert_equal({}, s)
		assert_equal({:key=>"value"}, s2)
	end

	def test_merge!
		s = SKH.new
		s2 = s.merge!({"key"=>"value"})
		h = {:key=>"value"}
		assert_equal(h, s)
		assert_equal(h, s2)
	end

	def test_store
		s = SKH.new
		s.store(:sym1, "value1")
		s.store("str1", "value2")
		s[:sym2] = "value3"
		s["str2"] = "value4"

		assert_equal({:sym1=>"value1", :str1=>"value2", :sym2=>"value3", :str2=>"value4"}, s)
	end
end

describe EimXML::DSL do
	it "scope is in instance of EimXML::DSL" do
		outer = inner = nil
		e3 = e2 = nil
		block_executed = false
		e = EimXML::DSL.element(:out, :k1=>"v1") do
			outer = self
			e2 = element(:in, :k2=>"v2") do
				block_executed = true
				inner = self
				e3 = element(:deep)
			end
		end

		block_executed.should == true
		outer.should be_kind_of(EimXML::DSL)
		inner.should be_kind_of(EimXML::DSL)
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

describe "Subclass of EimXML::BaseDSL" do
	class DSL1 < EimXML::BaseDSL
		register([EimXML::Element, "call"])
		register(Hash)
		register(String, Array, Object)
	end

	it "register" do
		lambda{EimXML::DSL.call(:dummy)}.should raise_error(NoMethodError)
		lambda{EimXML::BaseDSL.call(:dummy)}.should raise_error(NoMethodError)
		lambda{DSL1.element(:dummy)}.should raise_error(NoMethodError)
		DSL1.call(:dummy).should be_kind_of(EimXML::Element)
		DSL1.hash.should be_kind_of(Hash)
		DSL1.string.should be_kind_of(String)
		DSL1.array.should be_kind_of(Array)
		DSL1.object.should be_kind_of(Object)
	end
end

describe EimXML::OpenDSL do
	it "scope of block is one of outside" do
		@scope_checker_variable = 1
		block_executed = false
		d = EimXML::OpenDSL.new do |d|
			block_executed = true
			d.should be_kind_of(EimXML::OpenDSL)
			d.container.should be_nil
			d.element(:base, :key1=>"v1") do
				@scope_checker_variable.should == 1
				self.should_not be_kind_of(EimXML::Element)
				d.container.should be_kind_of(EimXML::Element)
				d.container.should == EimXML::Element.new(:base, :key1=>"v1")
				d.element(:sub, :key2=>"v2") do
					d.container.should be_kind_of(EimXML::Element)
					d.container.should == EimXML::Element.new(:sub, :key2=>"v2")
				end
				d.element(:sub2).should == EimXML::Element.new(:sub2)
			end
		end
		block_executed.should be_true
	end

	it "DSL methods return element" do
		d = EimXML::OpenDSL.new
		d.container.should be_nil
		r = d.element(:base, :key1=>"v1") do
			d.element(:sub, :key2=>"v2")
		end
		r.should == EimXML::DSL.element(:base, :key1=>"v1") do
			element(:sub, :key2=>"v2")
		end
	end

	it "DSL method's block given instance of OpenDSL" do
		e = EimXML::OpenDSL.new.element(:base) do |d|
			d.should be_kind_of(EimXML::OpenDSL)
			d.container.name.should == :base
			d.element(:sub) do |d2|
				d2.object_id.should == d.object_id
			end
		end

		e.should == EimXML::DSL.element(:base) do
			element(:sub)
		end
	end

	it "ensure reset container when error raised" do
		EimXML::OpenDSL.new do |d|
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
		r = EimXML::OpenDSL.new.element(:base) do |d|
			d.add "text"
			d.element(:sub) do
				s = EimXML::Element.new(:sub)
				s.add("sub text")
				d.add("sub text").should == s
			end
		end

		r.should == EimXML::DSL.element(:base) do
			add "text"
			element(:sub) do
				add "sub text"
			end
		end
	end

	it "respond to <<" do
		r = EimXML::OpenDSL.new.element(:base) do |d|
			b = EimXML::Element.new(:base)
			b << "text" << "next"
			(d << "text" << "next").should == b
		end
		r.should == EimXML::DSL.element(:base) do
			add "text"
			add "next"
		end
	end

	it "can call directly element method" do
		r = EimXML::OpenDSL.element(:base) do |d|
			d.element(:sub)
			d.element(:sub2)
		end
		r.should == EimXML::DSL.element(:base) do
			element(:sub)
			element(:sub2)
		end
	end
end
