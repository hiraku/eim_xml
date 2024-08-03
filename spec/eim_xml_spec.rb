require 'eim_xml/dsl'

module Module.new::M
  include EimXML
  EDSL = EimXML::DSL

  describe PCString do
    it '.encode' do
      expect(described_class.encode("<>\"'&")).to eq('&lt;&gt;&quot;&apos;&amp;')
      expect(described_class.encode('&test;')).to eq('&amp;test;')
      expect(described_class.encode('&amp;')).to eq('&amp;amp;')
      expect(described_class.encode(:'sym&')).to eq('sym&amp;')
    end

    it '.new' do
      expect(described_class.new('&').encoded_string).to eq('&amp;')
      expect(described_class.new('&', true).encoded_string).to eq('&')
      pcs = described_class.new(:'sym&')
      expect(pcs.encoded_string).to eq('sym&amp;')
      expect(pcs.src).to eq(:'sym&')
    end

    describe '.[]' do
      it 'should return itself when given object is a PCString' do
        pcs = described_class.new('s')
        expect(described_class[pcs]).to equal(pcs)
      end

      it 'should return PCString.new(obj) if given obj is not a PCString' do
        o = 'str'
        r = described_class[o]
        r.is_a?(EimXML::PCString)
        expect(r.src).to eq(o)
      end
    end

    it '#==' do
      expect(described_class.new('str')).to eq(described_class.new('str'))
      expect(described_class.new('&')).to eq('&')
      expect(described_class.new('&', true)).not_to eq('&')
      expect(described_class.new('&', true)).to eq(described_class.new('&', true))
      expect(described_class.new('&')).to eq(described_class.new('&amp;', true))
    end

    describe '#write_to' do
      before do
        @pc = described_class.new('&amp;')
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
      expect { described_class.new('--') }.to raise_error(ArgumentError)
    end

    describe '#write_to' do
      it 'should return comment with markup' do
        expect(described_class.new('flat comment').write_to).to eq('<!-- flat comment -->')
        expect(described_class.new("multi-line\ncomment").write_to).to eq("<!-- multi-line\ncomment -->")
        expect(described_class.new('&').write_to).to eq('<!-- & -->')
      end

      it 'should return given destination' do
        s = ''
        expect(described_class.new('dummy').write_to(s)).to be_equal(s)
      end
    end
  end

  describe Element do
    let(:dummy_class) do
      Class.new(Element) do
        def chgname(name)
          self.name = name
        end
      end
    end

    it '#name' do
      e = described_class.new('el')
      expect(e.name).to eq(:el)
      expect { e.name = 'changed' }.to raise_error(NoMethodError)

      d = dummy_class.new('el1')
      expect(d.name).to eq(:el1)
      d.chgname(:el2)
      expect(d.name).to eq(:el2)
      d.chgname('el3')
      expect(d.name).to eq(:el3)
    end

    it '#attributes should return hash whose keys are Symbol' do
      e = described_class.new('el', 'a1' => 'v1', :a2 => 'v2', 'a3' => nil)
      expect(e.name).to eq(:el)
      expect(e.attributes).to eq({ a1: 'v1', a2: 'v2', a3: nil })
    end

    it '#[]' do
      e = described_class.new(:el, attr: 'value')
      e << 'test'
      expect(e[:attr]).to eq('value')
      expect(e[0]).to eq('test')
    end

    it '#add_attribute' do
      e = described_class.new('el')
      e.add_attribute('key_str', 'value1')
      e.add_attribute(:key_sym, 'value2')
      expect(e.attributes).to eq({ key_str: 'value1', key_sym: 'value2' })
      e.add_attribute(:nil, nil)
      expect(e.attributes).to eq({ key_str: 'value1', key_sym: 'value2', nil: nil })
    end

    it '#del_attribute' do
      e = described_class.new('el', { a1: 'v1', a2: 'v2' })
      e.del_attribute('a1')
      expect(e.attributes).to eq({ a2: 'v2' })
      e.del_attribute(:a2)
      expect(e.attributes).to eq({})
    end

    it '#contents' do
      sub = described_class.new('sub')
      e = described_class.new('el') << 'String1' << 'String2' << sub
      expect(e.contents).to eq(['String1', 'String2', sub])
    end

    it '#add' do
      e = described_class.new('el').add(described_class.new('sub'))
      expect(e).to be_kind_of(described_class)
      expect(e.name).to eq(:el)

      e = described_class.new('el')
      e.add(described_class.new('sub1'))
      e.add([described_class.new('sub2').add('text'), 'string'])
      expect(e.contents).to eq([described_class.new('sub1'), described_class.new('sub2').add('text'), 'string'])

      e = described_class.new('el')
      e.add(nil)
      expect(e.contents.size).to eq(0)

      e = described_class.new('el').add(:symbol)
      expect(e.contents).to eq([:symbol])
      expect(e.to_s).to eq('<el>symbol</el>')

      e = described_class.new('super') << described_class.new('sub')
      expect(e.name).to eq(:super)
      expect(e.contents).to eq([described_class.new('sub')])
    end

    describe '#write_to' do
      it 'should return flatten string' do
        expect(described_class.new('e').write_to).to eq('<e />')

        e = described_class.new('super')
        e << described_class.new('sub')
        expect(e.write_to).to eq('<super><sub /></super>')
        e << described_class.new('sub2')
        expect(e.write_to).to eq('<super><sub /><sub2 /></super>')

        e = described_class.new('super') << 'content1'
        s = described_class.new('sub')
        s << 'content2'
        e << s
        expect(e.write_to).to eq('<super>content1<sub>content2</sub></super>')

        e = described_class.new('el')
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
        sym = described_class.new(:tag, attr: 'value')
        str_name = described_class.new('tag', attr: 'value')
        str_attr = described_class.new(:tag, 'attr' => 'value')

        expect(str_name.write_to).to eq(sym.write_to)
        expect(str_attr.write_to).to eq(sym.write_to)
      end
    end

    it 'encode special characters' do
      e = described_class.new('el') << "&\"'<>"
      e << PCString.new("&\"'<>", true)
      e.attributes['key'] = PCString.new("&\"'<>", true)
      expect(e.to_s).to eq(%[<el key='&\"'<>'>&amp;&quot;&apos;&lt;&gt;&\"'<></el>])
    end

    it '#dup' do
      e = described_class.new('el')
      e.attributes['key'] = 'value'
      e << 'String'
      e << 'Freeze'.freeze
      s = described_class.new('sub')
      s.attributes['subkey'] = 'subvalue'
      e << s
      f = e.dup

      expect(f.attributes.object_id).to eq(e.attributes.object_id)
      expect(f.contents.object_id).to eq(e.contents.object_id)

      expect(f.to_s).to eq(e.to_s)
    end

    it '#clone' do
      e = described_class.new('el')
      e.attributes['key'] = 'value'
      e << 'String'
      e << 'Freeze'.freeze
      s = described_class.new('sub')
      s.attributes['subkey'] = 'subvalue'
      e << s
      f = e.clone

      expect(f.attributes.object_id).to eq(e.attributes.object_id)
      expect(f.contents.object_id).to eq(e.contents.object_id)

      expect(f.to_s).to eq(e.to_s)
    end

    it '#==' do
      e1 = described_class.new('el')
      e1.attributes['key'] = 'value'
      s = described_class.new('sub')
      s << 'String'
      e1 << s
      e2 = e1.dup
      expect(e2).to eq(e1)

      e3 = described_class.new('e')
      e3.attributes['key'] = 'value'
      s = described_class.new('sub')
      s << 'String'
      e3 << s
      expect(e3).not_to eq(e1)

      e3 = described_class.new('e')
      e3.attributes['k'] = 'value'
      s = described_class.new('sub')
      s << 'String'
      e3 << s
      expect(e3).not_to eq(e1)

      e3 = described_class.new('e')
      e3.attributes['key'] = 'v'
      s = described_class.new('sub')
      s << 'String'
      e3 << s
      expect(e3).not_to eq(e1)

      e3 = described_class.new('e')
      e3.attributes['key'] = 'value'
      s = described_class.new('sub')
      s << 'S'
      e3 << s
      expect(e3).not_to eq(e1)

      e3 = described_class.new('e')
      e3.attributes['key'] = 'value'
      s = described_class.new('s')
      s << 'String'
      e3 << s
      expect(e3).not_to eq(e1)

      expect('string').not_to eq(e1)
    end

    describe '.new' do
      it 'should convert name of attributes to Symbol' do
        e = described_class.new(:e, 'a' => 'v')
        expect(e.attributes.keys).to eq([:a])
        expect(e[:a]).to eq('v')
      end

      it 'with block' do
        base = nil
        e = described_class.new('base') do |b|
          b['attr'] = 'value'
          b << described_class.new('sub')
          base = b
        end
        expect(base.object_id).to eq(e.object_id)

        e2 = described_class.new('base', attr: 'value')
        e2 << described_class.new('sub')
        expect(e2).to eq(e)

        e = described_class.new('base') do |b|
          b << described_class.new('sub1') do |s|
            s << described_class.new('sub12')
          end
          b << described_class.new('sub2')
        end
        base = described_class.new('base')
        sub1 = described_class.new('sub1')
        sub1 << described_class.new('sub12')
        sub2 = described_class.new('sub2')
        base << sub1 << sub2
        expect(e).to eq(base)
      end
    end

    it '#match' do
      e = described_class.new(:tag, attr: 'value')
      expect(e.match(:tag)).to be true
      expect(e.match(:tag, attr: 'value')).to be true
      expect(e.match(:t)).to be false
      expect(e.match(:tag, attr2: 'value')).to be false
      expect(e.match(:tag, attr: 'value2')).to be false
      expect(e.match(:tag, attr: /val/)).to be true

      expect(e.match(described_class.new(:tag))).to be true
      expect(e.match(described_class.new(:tag, attr: 'value'))).to be true
      expect(e.match(described_class.new(:tag, attr: /alu/))).to be true
      expect(e.match(described_class.new(:t))).to be false
      expect(e.match(described_class.new(:tag, attr2: 'value'))).to be false
      expect(e.match(described_class.new(:tag, attr: 'value2'))).to be false
      expect(e.match(described_class.new(:tag, attr: /aul/))).to be false
      expect(e.match(described_class.new(:tag, attr: PCString.new('value')))).to be true
      expect(described_class.new(:tag, attr: PCString.new('value'))).to match(e)

      expect(e.match(described_class.new(:tag, attr: nil))).to be false
      expect(e.match(described_class.new(:tag, nonattr: nil))).to be true

      expect(!!e.match(/ag/)).to be true
      expect(!!e.match(/elem/)).to be false

      expect(e.match(described_class)).to be true
      expect(e.match(dummy_class)).to be false
      expect(e.match(String)).to be false

      e = described_class.new(:element)
      e << described_class.new(:sub)
      e << 'text'
      expect(e.match(EDSL.element(:element) { element(:sub) })).to be true
      expect(e.match(EDSL.element(:element) { element(:other) })).to be false
      expect(e.match(EDSL.element(:element) { add('text') })).to be true
      expect(e.match(EDSL.element(:element) { add('other') })).to be false
      expect(e.match(EDSL.element(:element) { add(/ex/) })).to be true
      expect(e.match(EDSL.element(:element) { add(/th/) })).to be false
      expect(e.match(EDSL.element(:element) { add(/sub/) })).to be false

      e = described_class.new(:t, a: '&')
      expect(e).to match(described_class.new(:t, a: '&'))
      expect(e).to match(described_class.new(:t, a: PCString.new('&amp;', true)))
      expect(e).to match(described_class.new(:t, a: PCString.new('&')))

      expect(described_class.new(:t, 'a' => 'v')).to match(described_class.new(:t, a: 'v'))
    end

    it '#=~' do
      e = described_class.new(:tag, attr: 'value', a2: 'v2')
      expect(e).to match(:tag)
      expect(e).to match(described_class.new(:tag))
      expect(e).to match(described_class.new(:tag, a2: 'v2'))
      expect(e).to match(described_class.new(:tag, attr: /alu/))
      expect(e).to match(described_class.new(:tag, attr: PCString.new('value')))
      expect(e).not_to match(:t)
      expect(e).not_to match(described_class.new(:t))
      expect(e).not_to match(described_class.new(:tag, attr: /aul/))

      e = described_class.new(:t, a: '&')
      expect(e).to match(described_class.new(:t, a: '&'))
      expect(e).to match(described_class.new(:t, a: PCString.new('&amp;', true)))
      expect(e).to match(described_class.new(:t, a: PCString.new('&')))
    end

    %w[has? has_element? include?].each do |method|
      it "##{method}" do
        e = described_class.new(:base) do |b|
          b << described_class.new(:sub) do |s|
            s << described_class.new(:deep) do |d|
              d << 'text'
              d << PCString.new('&amp;', true)
              d << '<'
            end
          end
          b << described_class.new(:sub, attr: 'value')
        end

        expect(e.send(method, :sub)).to be true
        expect(e.send(method, :sub, attr: 'value')).to be true
        expect(e.send(method, :sub, attr: 'value', attr2: '')).to be false
        expect(e.send(method, :deep)).to be true

        expect(e.send(method, String)).to be true
        expect(e.send(method, PCString)).to be true

        d = described_class.new(:deep)
        d << 'text'
        d << PCString.new('&amp;', true)
        d << '<'
        expect(e.send(method, d)).to be true

        d = described_class.new(:deep)
        d << PCString.new('text', true)
        d << '&'
        d << PCString.new('&lt;', true)
        expect(e.send(method, d)).to be true
      end
    end

    it '#find' do
      s1 = described_class.new(:sub)
      d = described_class.new(:deep)
      d << '3rd'
      s1 << '2nd' << d
      s2 = described_class.new(:sub, attr: 'value')
      e = described_class.new(:base)
      e << '1st' << s1 << s2

      expect(e.find(:deep)).to be_kind_of(described_class)
      expect(e.find(:deep).name).to eq(:found)
      expect(e.find(:deep).contents).to eq([d])
      expect(e.find(:sub).contents).to eq([s1, s2])
      expect(e.find(//).contents).to eq([e, s1, d, s2])
      expect(e.find(:sub, attr: 'value').contents).to eq([s2])
      expect(e.find(String).contents).to eq(['1st', '2nd', '3rd'])
    end
  end
end
