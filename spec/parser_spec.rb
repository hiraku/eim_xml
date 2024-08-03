require 'eim_xml/parser'

module Module.new::M # rubocop:disable Style/ClassAndModuleChildren
  include EimXML

  describe Parser do
    def parse(src)
      Parser.new(src).parse
    end

    it "'parser' method for test" do
      s = ' <e /> '
      expect(parse(s)).to eq(described_class.new(s).parse)
    end

    it '#parse with empty element' do
      expect(parse('<e />')).to eq(Element.new('e'))
      expect(parse('<e/>')).to eq(Element.new('e'))

      expect(parse(%(<e key="value"/>))).to eq(Element.new('e', key: 'value'))
      expect(parse(%(<e key='value'/>))).to eq(Element.new('e', key: 'value'))
      expect(parse(%(<e key="value" />))).to eq(Element.new('e', key: 'value'))
      expect(parse(%(<e key='value' />))).to eq(Element.new('e', key: 'value'))

      expect(parse(%(<e key="value" key2="value2"/>))).to eq(Element.new('e', key: 'value', key2: 'value2'))
      expect(parse(%(<e key="value" key2="value2" />))).to eq(Element.new('e', key: 'value', key2: 'value2'))

      s = ' <e1 /> <e2 /> '
      p = described_class.new(s)
      expect(p.parse).to eq(PCString.new(' '))
      expect(p.parse).to eq(Element.new('e1'))
      expect(p.parse).to eq(PCString.new(' '))
      expect(p.parse).to eq(Element.new('e2'))
    end

    it '#parse with nonempty element' do
      expect(parse('<super><sub /></super>')).to eq(Element.new('super') << Element.new('sub'))

      expect(parse('<out><in></in></out>')).to eq(Element.new('out') << Element.new('in'))

      expect { parse('<el></e>') }.to raise_error(ParseError, 'End tag mismatched.')
      expect { parse('<el><></el>') }.to raise_error(ParseError, 'Syntax error.')
    end

    it '#parse with string' do
      e = parse('string&amp;')
      expect(e).to be_a(PCString)
      expect(e.to_s).to eq('string&amp;')
      e = parse(' string &amp; ')
      expect(e).to be_a(PCString)
      expect(e.to_s).to eq(' string &amp; ')

      e = Element.new('e')
      e << PCString.new(' string ')
      expect(parse('<e> string </e>')).to eq(e)

      e = Element.new('e')
      e << PCString.new('string')
      expect(parse('<e>string</e>')).to eq(e)
    end

    it '#parse escaped characters' do
      e = parse('&amp;&quot;&apos;&lt;&gt;')
      expect(e.to_s).to eq('&amp;&quot;&apos;&lt;&gt;')
      expect(e.src).to eq("&\"'<>")
    end

    it '#parse with holding space' do
      s = "<e> string with space\n</e>"
      e = Element.new('e')
      e << PCString.new(" string with space\n")
      expect(parse(s)).to eq(e)
      expect(parse(s).to_s).to eq(s)

      s = "<ns:e> string with space\n</ns:e>"
      e = Element.new('ns:e')
      e << PCString.new(" string with space\n")
      expect(parse(s)).to eq(e)
      expect(parse(s).to_s).to eq(s)

      s = '<a> string without space <b> string with space <a> string with space 2 </a> </b>  </a>'
      oa = Element.new('a') << PCString.new(' string without space ')
      b = Element.new('b')
      b << PCString.new(' string with space ')
      ia = Element.new('a')
      ia << PCString.new(' string with space 2 ')
      b << ia
      b << PCString.new(' ')
      oa << b
      oa << PCString.new('  ')
      expect(parse(s)).to eq(oa)
      expect(parse(s).to_s).to eq(s)

      s = '<a><b/></a>'
      a = Element.new('a')
      b = Element.new('b')
      a << b
      expect(parse(s)).to eq(a)
      expect(parse(s).to_s).to eq('<a><b /></a>')
    end
  end
end
