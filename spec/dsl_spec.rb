require 'eim_xml/dsl'

module Module.new::M # rubocop:disable Style/ClassAndModuleChildren
  include EimXML
  EDSL = EimXML::DSL

  describe EimXML::DSL do
    it 'scope is in instance of DSL' do
      outer = inner = nil
      e3 = e2 = nil
      block_executed = false
      e = EDSL.element(:out, k1: 'v1') do
        outer = self
        e2 = element(:in, k2: 'v2') do
          block_executed = true
          inner = self
          e3 = element(:deep)
        end
      end

      expect(block_executed).to be(true)
      expect(outer).to be_a(EDSL)
      expect(inner).to be_a(EDSL)
      expect(outer).to equal(inner)

      expect(e.name).to eq(:out)
      expect(e[:k1]).to eq('v1')
      expect(e[0].name).to eq(:in)
      expect(e[0][:k2]).to eq('v2')
      expect(e[0][0].name).to eq(:deep)
      expect(e2).to equal(e[0])
      expect(e3).to equal(e[0][0])
    end

    it '#comment' do
      expect(Comment).to receive(:new).with('comment').and_return(:success)
      expect(EDSL.comment('comment')).to eq(:success)
    end

    it '#import_variables' do
      d = EDSL.new
      o = Object.new
      o.instance_variable_set('@v1', 1)
      o.instance_variable_set('@v2', '2')
      o.instance_variable_set('@_v3', :t)
      o.instance_variable_set('@__v4', 4)
      o.instance_variable_set('@_container', :t)
      orig_c = d.instance_variable_get('@_container')

      expect(d.import_variables(o)).to equal(d)

      expect(d.instance_variable_get('@_container')).to eq(orig_c)
      expect(d.instance_variables.map(&:to_s).sort).to eq(['@v1', '@v2', '@__v4'].sort)
      expect(d.instance_variable_get('@v1')).to eq(1)
      expect(d.instance_variable_get('@v2')).to eq('2')
      expect(d.instance_variable_get('@__v4')).to eq(4)
    end

    describe '#_push' do
      before do
        @dsl = Class.new(EimXML::DSL) do
          def call_push(content)
            _push(content) do
              element(:e)
            end
          end

          def exec
            element(:e) do
              element(:f)
            end
          end
        end
      end

      it 'returns given container' do
        a = []
        expect(@dsl.new.call_push(a)).to equal(a)
        expect(a).to eq([EimXML::Element.new(:e)])

        expect(@dsl.new.exec).to eq(EimXML::Element.new(:e).add(EimXML::Element.new(:f)))
      end
    end
  end

  describe 'Subclass of BaseDSL' do
    let(:dsl1) do
      Class.new(EimXML::BaseDSL) do
        register([EimXML::Element, 'call'])
        register(Hash)
        register(String, Array, Object)
      end
    end

    it 'register' do
      expect { EDSL.call(:dummy) }.to raise_error(NoMethodError)
      expect { BaseDSL.call(:dummy) }.to raise_error(NoMethodError)
      expect { dsl1.element(:dummy) }.to raise_error(NoMethodError)
      expect(dsl1.call(:dummy)).to be_a(Element)
      expect(dsl1.hash).to be_a(Hash)
      expect(dsl1.string).to be_a(String)
      expect(dsl1.array).to be_a(Array)
      expect(dsl1.object).to be_a(Object)
    end
  end

  describe EimXML::OpenDSL do
    it 'scope of block is one of outside' do
      @scope_checker_variable = 1
      block_executed = false
      OpenDSL.new do |dsl|
        block_executed = true
        expect(dsl).to be_a(OpenDSL)
        expect(dsl.container).to be_nil
        dsl.element(:base, key1: 'v1') do
          expect(@scope_checker_variable).to eq(1)
          expect(self).not_to be_a(Element)
          expect(dsl.container).to be_a(Element)
          expect(dsl.container).to eq(Element.new(:base, key1: 'v1'))
          dsl.element(:sub, key2: 'v2') do
            expect(dsl.container).to be_a(Element)
            expect(dsl.container).to eq(Element.new(:sub, key2: 'v2'))
          end
          expect(dsl.element(:sub2)).to eq(Element.new(:sub2))
        end
      end
      expect(block_executed).to be true
    end

    it 'DSL methods return element' do
      d = OpenDSL.new
      expect(d.container).to be_nil
      r = d.element(:base, key1: 'v1') do
        d.element(:sub, key2: 'v2')
      end
      expect(r).to eq(EDSL.element(:base, key1: 'v1') do
        element(:sub, key2: 'v2')
      end)
    end

    it "DSL method's block given instance of OpenDSL" do
      e = OpenDSL.new.element(:base) do |d|
        expect(d).to be_a(OpenDSL)
        expect(d.container.name).to eq(:base)
        d.element(:sub) do |d2|
          expect(d2).to equal(d)
        end
      end

      expect(e).to eq(EDSL.element(:base) do
        element(:sub)
      end)
    end

    it 'ensure reset container when error raised' do
      OpenDSL.new do |d|
        d.element(:base) do
          d.element(:sub) do
            raise 'OK'
          end
        rescue RuntimeError => e
          raise unless e.message == 'OK'

          expect(d.container.name).to eq(:base)
          raise
        end
      rescue RuntimeError => e
        raise unless e.message == 'OK'

        expect(d.container).to be_nil
      end
    end

    it 'respond to add' do
      r = OpenDSL.new.element(:base) do |d|
        d.add 'text'
        d.element(:sub) do
          s = Element.new(:sub)
          s.add('sub text')
          expect(d.add('sub text')).to eq(s)
        end
      end

      expect(r).to eq(EDSL.element(:base) do
        add 'text'
        element(:sub) do
          add 'sub text'
        end
      end)
    end

    it 'respond to <<' do
      r = OpenDSL.new.element(:base) do |d|
        b = Element.new(:base)
        b << 'text' << 'next'
        expect(d << 'text' << 'next').to eq(b)
      end
      expect(r).to eq(EDSL.element(:base) do
        add 'text'
        add 'next'
      end)
    end

    it 'can call directly element method' do
      r = OpenDSL.element(:base) do |d|
        d.element(:sub)
        d.element(:sub2)
      end
      expect(r).to eq(EDSL.element(:base) do
        element(:sub)
        element(:sub2)
      end)
    end
  end
end
