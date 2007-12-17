# Test for eim_xml/parser.rb
#
# Copyright (C) 2006, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.

require "test/unit"
require "eim_xml/parser"

class ParserTest < Test::Unit::TestCase
	include EimXML

	def parse(src)
		Parser.new(src).parse
	end

	def test_parse
		s = " <e /> "
		assert_equal(Parser.new(s).parse, parse(s))
	end

	def test_parse_empty_element
		assert_equal(Element.new("e"), parse("<e />"))
		assert_equal(Element.new("e"), parse("<e/>"))

		assert_equal(Element.new("e", "key"=>"value"), parse(%[<e key="value"/>]))
		assert_equal(Element.new("e", "key"=>"value"), parse(%[<e key='value'/>]))
		assert_equal(Element.new("e", "key"=>"value"), parse(%[<e key="value" />]))
		assert_equal(Element.new("e", "key"=>"value"), parse(%[<e key='value' />]))

		assert_equal(Element.new("e", "key"=>"value", "key2"=>"value2"), parse(%[<e key="value" key2="value2"/>]))
		assert_equal(Element.new("e", "key"=>"value", "key2"=>"value2"), parse(%[<e key="value" key2="value2" />]))

		s = " <e1 /> <e2 /> "
		p = Parser.new(s)
		assert_equal(Element.new("e1"), p.parse)
		assert_equal(Element.new("e2"), p.parse)
	end

	def test_parse_nonempty_element
		assert_equal(Element.new("super") << Element.new("sub"), parse("<super><sub /></super>"))
		e = assert_raises(ParseError){parse("<el></e>")}
		assert_equal("End tag mismatched.", e.message)
		e = assert_raises(ParseError){parse("<el><></el>")}
		assert_equal("Syntax error.", e.message)
	end

	def test_parse_string
		e = parse("string&amp;")
		assert_instance_of(PCString, e)
		assert_equal("string&amp;", e.to_s)
		e = parse(" string &amp; ")
		assert_instance_of(PCString, e)
		assert_equal("string &amp;", e.to_s)

		e = Element.new("e")
		e << PCString.new("string")
		assert_equal(e, parse("<e> string </e>"))
		assert_equal(e, parse("<e>string</e>"))
	end

	def test_hold_space
		s = "<e> string with space\n</e>"
		e = Element.new("e")
		e << PCString.new("string with space", true)
		assert_equal(e, parse(s))

		e = Element.new("e").hold_space
		e << PCString.new(" string with space\n", true)
		assert_not_equal(e, Parser.new(s).parse)
		assert_equal(e, Parser.new(s).parse(true))
		assert_equal(e, Parser.new(s, "dummy", "e").parse)
		assert_equal(e, Parser.new(s, /dummy/, /e/).parse)
		assert_equal(e, Parser.new(s, :dummy, :e).parse)
		assert_equal(e, Parser.new(s, :dummy, /^(.*:)?e$/).parse)

		s = "<ns:e> string with space\n</ns:e>"
		e = Element.new("ns:e")
		e << PCString.new("string with space")
		assert_equal(e, Parser.new(s).parse)

		e = Element.new("ns:e").hold_space
		e << PCString.new(" string with space\n")
		assert_equal(e, Parser.new(s, /^(.*:)?e$/).parse)

		s = "<a> string without space <b> string with space <a> string with space 2 </a> </b>  </a>"
		oa = Element.new("a") << PCString.new("string without space")
		b = Element.new("b").hold_space
		b << PCString.new(" string with space ")
		ia = Element.new("a").hold_space
		ia << PCString.new(" string with space 2 ")
		b << ia
		b << PCString.new(" ")
		oa << b
		assert_equal(oa, Parser.new(s, "b").parse)

		s = "<a><b/></a>"
		a = Element.new("a").hold_space
		b = Element.new("b").hold_space
		a << b
		assert_equal(a, Parser.new(s, "a").parse)
	end
end
