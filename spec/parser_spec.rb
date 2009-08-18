require "eim_xml/parser"

module Module.new::M
	include EimXML

	describe Parser do
		def parse(src)
			Parser.new(src).parse
		end

		it "'parser' method for test" do
			s = " <e /> "
			parse(s).should == Parser.new(s).parse
		end

		it "#parse with empty element" do
			parse("<e />").should == Element.new("e")
			parse("<e/>").should == Element.new("e")

			parse(%[<e key="value"/>]).should == Element.new("e", :key=>"value")
			parse(%[<e key='value'/>]).should == Element.new("e", :key=>"value")
			parse(%[<e key="value" />]).should == Element.new("e", :key=>"value")
			parse(%[<e key='value' />]).should == Element.new("e", :key=>"value")

			parse(%[<e key="value" key2="value2"/>]).should == Element.new("e", :key=>"value", :key2=>"value2")
			parse(%[<e key="value" key2="value2" />]).should == Element.new("e", :key=>"value", :key2=>"value2")

			s = " <e1 /> <e2 /> "
			p = Parser.new(s)
			p.parse.should == Element.new("e1")
			p.parse.should == Element.new("e2")
		end

		it "#parse with nonempty element" do
			parse("<super><sub /></super>").should == Element.new("super") << Element.new("sub")

			parse("<out><in></in></out>").should == Element.new("out") << Element.new("in")

			lambda{parse("<el></e>")}.should raise_error(ParseError, "End tag mismatched.")
			lambda{parse("<el><></el>")}.should raise_error(ParseError, "Syntax error.")
		end

		it "#parse with string" do
			e = parse("string&amp;")
			e.should be_kind_of(PCString)
			e.to_s.should == "string&amp;"
			e = parse(" string &amp; ")
			e.should be_kind_of(PCString)
			e.to_s.should == "string &amp;"

			e = Element.new("e")
			e << PCString.new("string")
			parse("<e> string </e>").should == e
			parse("<e>string</e>").should == e
		end

		it "#parse with holding space" do
			s = "<e> string with space\n</e>"
			e = Element.new("e")
			e << PCString.new("string with space", true)
			parse(s).should == e

			e = Element.new("e").preserve_space
			e << PCString.new(" string with space\n", true)
			Parser.new(s).parse.should_not == e
			Parser.new(s).parse(true).should == e
			Parser.new(s, "dummy", "e").parse.should == e
			Parser.new(s, /dummy/, /e/).parse.should == e
			Parser.new(s, :dummy, :e).parse.should == e
			Parser.new(s, :dummy, /^(.*:)?e$/).parse.should == e

			s = "<ns:e> string with space\n</ns:e>"
			e = Element.new("ns:e")
			e << PCString.new("string with space")
			Parser.new(s).parse.should == e

			e = Element.new("ns:e").preserve_space
			e << PCString.new(" string with space\n")
			Parser.new(s, /^(.*:)?e$/).parse.should == e

			s = "<a> string without space <b> string with space <a> string with space 2 </a> </b>  </a>"
			oa = Element.new("a") << PCString.new("string without space")
			b = Element.new("b").preserve_space
			b << PCString.new(" string with space ")
			ia = Element.new("a").preserve_space
			ia << PCString.new(" string with space 2 ")
			b << ia
			b << PCString.new(" ")
			oa << b
			Parser.new(s, "b").parse.should == oa

			s = "<a><b/></a>"
			a = Element.new("a").preserve_space
			b = Element.new("b").preserve_space
			a << b
			Parser.new(s, "a").parse.should == a
		end
	end
end
