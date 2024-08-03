require 'eim_xml/formatter'
require 'eim_xml/dsl'

describe EimXML::Formatter do
  describe '.write' do
    it 'returns output object' do
      s = ''
      expect(described_class.write(EimXML::Element.new(:e), out: s)).to be_equal(s)
    end

    it 'returns string when destination not given' do
      r = described_class.write(EimXML::Element.new(:e))
      expect(r).to be_kind_of(String)
    end

    describe 'should return formatted elements string' do
      def write(*arg)
        EimXML::Formatter.write(*arg)
      end

      it '(element not have content)' do
        expect(write(EimXML::DSL.element(:e))).to eq("<e />\n")
      end

      it '(empty element which has attributes)' do
        r = (write(EimXML::DSL.element(:e, a1: 'v1', a2: 'v2')) =~ %r{<e (a.='v.') (a.='v.') />})
        expect(r).not_to be_nil
        expect([Regexp.last_match(1), Regexp.last_match(2)].sort).to eq(["a1='v1'", "a2='v2'"])
      end

      it '(element in element)' do
        e = EimXML::DSL.element(:e) do
          element(:s)
        end
        expect(write(e)).to eq <<~XML
          <e>
            <s />
          </e>
        XML
      end

      it '(elements in element)' do
        e = EimXML::DSL.element(:e) do
          element(:s1)
          element(:s2)
        end
        expect(write(e)).to eq <<~XML
          <e>
            <s1 />
            <s2 />
          </e>
        XML
      end

      it '(comment in element)' do
        e = EimXML::DSL.element(:e) do
          comment("multi\nline\n pre-indented\n  comment")
        end
        expect(write(e)).to eq <<~XML
          <e>
            <!-- multi
          line
           pre-indented
            comment -->
          </e>
        XML
      end

      it '(string in element)' do
        e = EimXML::Element.new(:e)
        e.add('string')
        expect(write(e)).to eq("<e>\n  string\n</e>\n")

        expect(write(EimXML::Element.new(:e, a: "&<>\n'\"").add("&<>\n'\""))).to eq(
          "<e a='&amp;&lt;&gt;\n&apos;&quot;'>\n  &amp;&lt;&gt;\n  &apos;&quot;\n</e>\n"
        )
        expect(write(EimXML::Element.new(:e, a: "&<>\n'\"").add(EimXML::PCString.new("&<>\n'\"", true)))).to eq(
          "<e a='&amp;&lt;&gt;\n&apos;&quot;'>\n  &<>\n  '\"\n</e>\n"
        )
      end

      it '(multi-line string in element)' do
        e = EimXML::Element.new(:e)
        e.add("multi\nline")
        expect(write(e)).to eq <<~XML
          <e>
            multi
            line
          </e>
        XML
      end

      describe '(preserve spaces' do
        it 'name of element' do
          e = EimXML::DSL.element(:e) do
            element(:pre1) do
              element(:sub1).add('text')
              element(:sub2)
            end
            element(:pre2).add("multi\nline\ntext")
            element(:sub1).add('text')
          end
          s = <<~XML
            <e>
              <pre1><sub1>text</sub1><sub2 /></pre1>
              <pre2>multi
            line
            text</pre2>
              <sub1>
                text
              </sub1>
            </e>
          XML

          expect(write(e, preservers: %i[pre1 pre2])).to eq(s)
        end

        it 'class of element' do
          m_pre = Class.new(EimXML::Element) do
            def initialize(name = nil)
              super(name || 'pre')
            end
          end

          m_p1 = Class.new(m_pre) do
            def initialize(name = nil)
              super(name || 'p1')
            end
          end

          m_p2 = Class.new(m_p1) do
            def initialize
              super('p2')
            end
          end

          e = EimXML::Element.new(:e)
          e << m_pre.new.add("text\nwith\nnewline")
          e << m_pre.new('dummy').add("t\nn")
          e << m_p1.new.add("t1\nn")
          e << m_p2.new.add("t2\nn")
          e << m_pre.new.add(EimXML::Element.new(:s).add("t\ns"))
          e << m_p2.new.add(EimXML::Element.new(:s).add("t\ns2"))
          e << EimXML::Element.new(:s).add(EimXML::Element.new(:s).add("t\ns"))

          s = <<~XML
            <e>
              <pre>text
            with
            newline</pre>
              <dummy>t
            n</dummy>
              <p1>t1
            n</p1>
              <p2>t2
            n</p2>
              <pre><s>t
            s</s></pre>
              <p2><s>t
            s2</s></p2>
              <s>
                <s>
                  t
                  s
                </s>
              </s>
            </e>
          XML
          expect(write(e, preservers: [m_pre])).to eq(s)
        end
      end

      it '(all)' do
        s = <<~XML
          <base>
            <sub1 />
            <sub2>
              text2
            </sub2>
            <sub3 a1='v1'>
              <sub31 />
              <sub32>
                text32
              </sub32>
            </sub3>
            <sub4>
              multi-line
              text
            </sub4>
            <sub5>
              <sub51 />
              sub52
              <sub53 />
              sub54-1
              sub54-2
            </sub5>
          </base>
        XML
        e = EimXML::DSL.element(:base) do
          element(:sub1)
          element(:sub2).add('text2')
          element(:sub3, a1: 'v1') do
            element(:sub31)
            element(:sub32).add('text32')
          end
          element(:sub4).add("multi-line\ntext")
          element(:sub5) do
            element(:sub51)
            add('sub52')
            element(:sub53)
            add("sub54-1\nsub54-2")
          end
        end
        expect(write(e)).to eq(s)
      end
    end
  end
end

describe EimXML::Formatter::ElementWrapper do
  let(:out) { '' }
  let(:opt) { { out: out, preservers: [], a: 10, b: 20 } }
  let(:formatter) { EimXML::Formatter.new(opt) }

  let(:wrapper_class) do
    Class.new(EimXML::Formatter::ElementWrapper) do
      def initialize(mocks)
        @mocks = mocks
      end

      def contents(_option)
        @mocks
      end
    end
  end

  let(:mocks) { [double(:m1).as_null_object, double(:m2).as_null_object] }
  let(:wrapper) { wrapper_class.new(mocks) }

  let(:xml) do
    EimXML::Element.new(:e) do |e|
      e << wrapper
    end
  end

  describe '#each' do
    it 'will give options from formatter' do
      expect(wrapper).to receive(:contents).with(a: 10, b: 20).and_return([])
      formatter.write(xml)
    end

    it 'yield result of contents' do
      mocks.each_with_index do |mock, index|
        expect(mock).to receive(:to_s).and_return("m#{index}")
      end
      formatter.write(xml)
      expect(out).to eq("<e>\n  m0\n  m1\n</e>\n")
    end

    it 'raise error when subclass of ElementWrapper is not implement #contents' do
      wrapper_class2 = Class.new(described_class)
      xml << wrapper_class2.new

      expect { formatter.write(xml) }.to raise_error(NoMethodError)
    end
  end
end
