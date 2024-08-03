require 'eim_xml/dsl'

module Module.new::M
  include EimXML
  EDSL = EimXML::DSL

  describe PCString do
    it '.encode' do
      expect(PCString.encode("<>\"'&")).to eq('&lt;&gt;&quot;&apos;&amp;')
      expect(PCString.encode('&test;')).to eq('&amp;test;')
      expect(PCString.encode('&amp;')).to eq('&amp;amp;')
      expect(PCString.encode(:'sym&')).to eq('sym&amp;')
    end

    it '.new' do
      expect(PCString.new('&').encoded_string).to eq('&amp;')
      expect(PCString.new('&', true).encoded_string).to eq('&')
      pcs = PCString.new(:'sym&')
      expect(pcs.encoded_string).to eq('sym&amp;')
      expect(pcs.src).to eq(:'sym&')
    end

    describe '.[]' do
      it 'should return itself when given object is a PCString' do
        pcs = PCString.new('s')
        expect(PCString[pcs]).to equal(pcs)
      end

      it 'should return PCString.new(obj) if given obj is not a PCString' do
        o = 'str'
        r = PCString[o]
        r.is_a?(EimXML::PCString)
        expect(r.src).to eq(o)
      end
    end

    it '#==' do
      expect(PCString.new('str')).to eq(PCString.new('str'))
      expect(PCString.new('&')).to eq('&')
      expect(PCString.new('&', true)).not_to eq('&')
      expect(PCString.new('&', true)).to eq(PCString.new('&', true))
      expect(PCString.new('&')).to eq(PCString.new('&amp;', true))
    end

    describe '#write_to' do
      before do
        @pc = PCString.new('&amp;')
      end

      it 'should return encoded string' do
        expect(@pc.write_to).to eq('&amp;amp;')
      end

      it 'should return given destination' do
        s = ''
        expect(@pc.write_to(s)).to be_equal(s)
      end
    end
  end

  describe Comment do
    it ".new should raise error if given string include '--'" do
      expect { Comment.new('--') }.to raise_error(ArgumentError)
    end

    describe '#write_to' do
      it 'should return comment with markup' do
        expect(Comment.new('flat comment').write_to).to eq('<!-- flat comment -->')
        expect(Comment.new("multi-line\ncomment").write_to).to eq("<!-- multi-line\ncomment -->")
        expect(Comment.new('&').write_to).to eq('<!-- & -->')
      end

      it 'should return given destination' do
        s = ''
        expect(Comment.new('dummy').write_to(s)).to be_equal(s)
      end
    end
  end

  describe Element do
    class Dummy < Element
      def chgname(name)
        self.name = name
      end
    end

    it '#name' do
      e = Element.new('el')
      expect(e.name).to eq(:el)
      expect { e.name = 'changed' }.to raise_error(NoMethodError)

      d = Dummy.new('el1')
      expect(d.name).to eq(:el1)
      d.chgname(:el2)
      expect(d.name).to eq(:el2)
      d.chgname('el3')
      expect(d.name).to eq(:el3)
    end

    it '#attributes should return hash whose keys are Symbol' do
      e = Element.new('el', 'a1' => 'v1', :a2 => 'v2', 'a3' => nil)
      expect(e.name).to eq(:el)
      expect(e.attributes).to eq({ a1: 'v1', a2: 'v2', a3: nil })
    end

    it '#[]' do
      e = Element.new(:el, attr: 'value')
      e << 'test'
      expect(e[:attr]).to eq('value')
      expect(e[0]).to eq('test')
    end

    it '#add_attribute' do
      e = Element.new('el')
      e.add_attribute('key_str', 'value1')
      e.add_attribute(:key_sym, 'value2')
      expect(e.attributes).to eq({ key_str: 'value1', key_sym: 'value2' })
      e.add_attribute(:nil, nil)
      expect(e.attributes).to eq({ key_str: 'value1', key_sym: 'value2', nil: nil })
    end

    it '#del_attribute' do
      e = Element.new('el', { a1: 'v1', a2: 'v2' })
      e.del_attribute('a1')
      expect(e.attributes).to eq({ a2: 'v2' })
      e.del_attribute(:a2)
      expect(e.attributes).to eq({})
    end

    it '#contents' do
      sub = Element.new('sub')
      e = Element.new('el') << 'String1' << 'String2' << sub
      expect(e.contents).to eq(['String1', 'String2', sub])
    end

    it '#add' do
      e = Element.new('el').add(Element.new('sub'))
      expect(e).to be_kind_of(Element)
      expect(e.name).to eq(:el)

      e = Element.new('el')
      e.add(Element.new('sub1'))
      e.add([Element.new('sub2').add('text'), 'string'])
      expect(e.contents).to eq([Element.new('sub1'), Element.new('sub2').add('text'), 'string'])

      e = Element.new('el')
      e.add(nil)
      expect(e.contents.size).to eq(0)

      e = Element.new('el').add(:symbol)
      expect(e.contents).to eq([:symbol])
      expect(e.to_s).to eq('<el>symbol</el>')

      e = Element.new('super') << Element.new('sub')
      expect(e.name).to eq(:super)
      expect(e.contents).to eq([Element.new('sub')])
    end

    describe '#write_to' do
      it 'should return flatten string' do
        expect(Element.new('e').write_to).to eq('<e />')

        e = Element.new('super')
        e << Element.new('sub')
        expect(e.write_to).to eq('<super><sub /></super>')
        e << Element.new('sub2')
        expect(e.write_to).to eq('<super><sub /><sub2 /></super>')

        e = Element.new('super') << 'content1'
        s = Element.new('sub')
        s << 'content2'
        e << s
        expect(e.write_to).to eq('<super>content1<sub>content2</sub></super>')

        e = Element.new('el')
        e.attributes['a1'] = 'v1'
        e.attributes['a2'] = "'\"<>&"
        s = e.write_to
        expect(s).to match(/\A<el ([^>]*) \/>\z/)
        expect(s).to match(/a1='v1'/)
        expect(s).to match(/a2='&apos;&quot;&lt;&gt;&amp;'/)
      end

      it 'should return string without attribute whose value is nil or false' do
        s = EimXML::Element.new('e', attr1: '1', attr2: true, attr3: nil, attr4: false).write_to
        re = /\A<e attr(.*?)='(.*?)' attr(.*?)='(.*?)' \/>\z/
        expect(s).to match(re)
        s =~ /\A<e attr(.*?)='(.*?)' attr(.*?)='(.*?)' \/>\z/
        expect([[$1, $2], [$3, $4]].sort).to eq([['1', '1'], ['2', 'true']])
      end

      it 'should return same string whenever name of element given with string or symbol' do
        sym = Element.new(:tag, attr: 'value')
        str_name = Element.new('tag', attr: 'value')
        str_attr = Element.new(:tag, 'attr' => 'value')

        expect(str_name.write_to).to eq(sym.write_to)
        expect(str_attr.write_to).to eq(sym.write_to)
      end
    end

    it 'encode special characters' do
      e = Element.new('el') << "&\"'<>"
      e << PCString.new("&\"'<>", true)
      e.attributes['key'] = PCString.new("&\"'<>", true)
      expect(e.to_s).to eq(%[<el key='&\"'<>'>&amp;&quot;&apos;&lt;&gt;&\"'<></el>])
    end

    it '#dup' do
      e = Element.new('el')
      e.attributes['key'] = 'value'
      e << 'String'
      e << 'Freeze'.freeze
      s = Element.new('sub')
      s.attributes['subkey'] = 'subvalue'
      e << s
      f = e.dup

      expect(f.attributes.object_id).to eq(e.attributes.object_id)
      expect(f.contents.object_id).to eq(e.contents.object_id)

      expect(f.to_s).to eq(e.to_s)
    end

    it '#clone' do
      e = Element.new('el')
      e.attributes['key'] = 'value'
      e << 'String'
      e << 'Freeze'.freeze
      s = Element.new('sub')
      s.attributes['subkey'] = 'subvalue'
      e << s
      f = e.clone

      expect(f.attributes.object_id).to eq(e.attributes.object_id)
      expect(f.contents.object_id).to eq(e.contents.object_id)

      expect(f.to_s).to eq(e.to_s)
    end

    it '#==' do
      e1 = Element.new('el')
      e1.attributes['key'] = 'value'
      s = Element.new('sub')
      s << 'String'
      e1 << s
      e2 = e1.dup
      expect(e2).to eq(e1)

      e3 = Element.new('e')
      e3.attributes['key'] = 'value'
      s = Element.new('sub')
      s << 'String'
      e3 << s
      expect(e3).not_to eq(e1)

      e3 = Element.new('e')
      e3.attributes['k'] = 'value'
      s = Element.new('sub')
      s << 'String'
      e3 << s
      expect(e3).not_to eq(e1)

      e3 = Element.new('e')
      e3.attributes['key'] = 'v'
      s = Element.new('sub')
      s << 'String'
      e3 << s
      expect(e3).not_to eq(e1)

      e3 = Element.new('e')
      e3.attributes['key'] = 'value'
      s = Element.new('sub')
      s << 'S'
      e3 << s
      expect(e3).not_to eq(e1)

      e3 = Element.new('e')
      e3.attributes['key'] = 'value'
      s = Element.new('s')
      s << 'String'
      e3 << s
      expect(e3).not_to eq(e1)

      expect('string').not_to eq(e1)
    end

    describe '.new' do
      it 'should convert name of attributes to Symbol' do
        e = Element.new(:e, 'a' => 'v')
        expect(e.attributes.keys).to eq([:a])
        expect(e[:a]).to eq('v')
      end

      it 'with block' do
        base = nil
        e = Element.new('base') do |b|
          b['attr'] = 'value'
          b << Element.new('sub')
          base = b
        end
        expect(base.object_id).to eq(e.object_id)

        e2 = Element.new('base', attr: 'value')
        e2 << Element.new('sub')
        expect(e2).to eq(e)

        e = Element.new('base') do |e|
          e <<= Element.new('sub1') do |e|
            e <<= Element.new('sub12')
          end
          e <<= Element.new('sub2')
        end
        base = Element.new('base')
        sub1 = Element.new('sub1')
        sub1 << Element.new('sub12')
        sub2 = Element.new('sub2')
        base << sub1 << sub2
        expect(e).to eq(base)
      end
    end

    it '#match' do
      e = Element.new(:tag, attr: 'value')
      expect(e.match(:tag)).to be true
      expect(e.match(:tag, attr: 'value')).to be true
      expect(e.match(:t)).to be false
      expect(e.match(:tag, attr2: 'value')).to be false
      expect(e.match(:tag, attr: 'value2')).to be false
      expect(e.match(:tag, attr: /val/)).to be true

      expect(e.match(Element.new(:tag))).to be true
      expect(e.match(Element.new(:tag, attr: 'value'))).to be true
      expect(e.match(Element.new(:tag, attr: /alu/))).to be true
      expect(e.match(Element.new(:t))).to be false
      expect(e.match(Element.new(:tag, attr2: 'value'))).to be false
      expect(e.match(Element.new(:tag, attr: 'value2'))).to be false
      expect(e.match(Element.new(:tag, attr: /aul/))).to be false
      expect(e.match(Element.new(:tag, attr: PCString.new('value')))).to be true
      expect(Element.new(:tag, attr: PCString.new('value'))).to match(e)

      expect(e.match(Element.new(:tag, attr: nil))).to be false
      expect(e.match(Element.new(:tag, nonattr: nil))).to be true

      expect(!!e.match(/ag/)).to be true
      expect(!!e.match(/elem/)).to be false

      expect(e.match(Element)).to be true
      expect(e.match(Dummy)).to be false
      expect(e.match(String)).to be false

      e = Element.new(:element)
      e << Element.new(:sub)
      e << 'text'
      expect(e.match(EDSL.element(:element) { element(:sub) })).to be true
      expect(e.match(EDSL.element(:element) { element(:other) })).to be false
      expect(e.match(EDSL.element(:element) { add('text') })).to be true
      expect(e.match(EDSL.element(:element) { add('other') })).to be false
      expect(e.match(EDSL.element(:element) { add(/ex/) })).to be true
      expect(e.match(EDSL.element(:element) { add(/th/) })).to be false
      expect(e.match(EDSL.element(:element) { add(/sub/) })).to be false

      e = Element.new(:t, a: '&')
      expect(e).to match(Element.new(:t, a: '&'))
      expect(e).to match(Element.new(:t, a: PCString.new('&amp;', true)))
      expect(e).to match(Element.new(:t, a: PCString.new('&')))

      expect(Element.new(:t, 'a' => 'v')).to match(Element.new(:t, a: 'v'))
    end

    it '#=~' do
      e = Element.new(:tag, attr: 'value', a2: 'v2')
      expect(e).to match(:tag)
      expect(e).to match(Element.new(:tag))
      expect(e).to match(Element.new(:tag, a2: 'v2'))
      expect(e).to match(Element.new(:tag, attr: /alu/))
      expect(e).to match(Element.new(:tag, attr: PCString.new('value')))
      expect(e).not_to match(:t)
      expect(e).not_to match(Element.new(:t))
      expect(e).not_to match(Element.new(:tag, attr: /aul/))

      e = Element.new(:t, a: '&')
      expect(e).to match(Element.new(:t, a: '&'))
      expect(e).to match(Element.new(:t, a: PCString.new('&amp;', true)))
      expect(e).to match(Element.new(:t, a: PCString.new('&')))
    end

    %w[has? has_element? include?].each do |method|
      it "##{method}" do
        e = Element.new(:base) do |b|
          b <<= Element.new(:sub) do |s|
            s <<= Element.new(:deep) do |d|
              d << 'text'
              d << PCString.new('&amp;', true)
              d << '<'
            end
          end
          b <<= Element.new(:sub, attr: 'value')
        end

        expect(e.send(method, :sub)).to be true
        expect(e.send(method, :sub, attr: 'value')).to be true
        expect(e.send(method, :sub, attr: 'value', attr2: '')).to be false
        expect(e.send(method, :deep)).to be true

        expect(e.send(method, String)).to be true
        expect(e.send(method, PCString)).to be true

        d = Element.new(:deep)
        d << 'text'
        d << PCString.new('&amp;', true)
        d << '<'
        expect(e.send(method, d)).to be true

        d = Element.new(:deep)
        d << PCString.new('text', true)
        d << '&'
        d << PCString.new('&lt;', true)
        expect(e.send(method, d)).to be true
      end
    end

    it '#find' do
      s1 = Element.new(:sub)
      d = Element.new(:deep)
      d << '3rd'
      s1 << '2nd' << d
      s2 = Element.new(:sub, attr: 'value')
      e = Element.new(:base)
      e << '1st' << s1 << s2

      expect(e.find(:deep)).to be_kind_of(Element)
      expect(e.find(:deep).name).to eq(:found)
      expect(e.find(:deep).contents).to eq([d])
      expect(e.find(:sub).contents).to eq([s1, s2])
      expect(e.find(//).contents).to eq([e, s1, d, s2])
      expect(e.find(:sub, attr: 'value').contents).to eq([s2])
      expect(e.find(String).contents).to eq(['1st', '2nd', '3rd'])
    end
  end
end
