require 'stringio'
require 'eim_xml/xhtml/dsl'

module Module.new::M
  include EimXML
  include EimXML::XHTML
  XDSL = XHTML::DSL

  describe XHTML do
    it 'DSL.base_ should raise NoMethodError' do
      expect { XDSL.base_ }.to raise_error(NoMethodError)
    end

    it 'HTML' do
      h = HTML.new(attr: 'value')
      expect(h).to eq(Element.new(:html, attr: 'value'))

      h = HTML.new do |e|
        e << Element.new(:sub)
      end
      h2 = HTML.new
      h2 << Element.new(:sub)
      expect(h2).to eq(h)

      expect { EimXML::DSL.html }.to raise_error(NoMethodError)
      expect(XDSL.html(key: 'v')).to eq(HTML.new(key: 'v'))
      expect(OpenDSL.html(key: 'v')).to eq(HTML.new(key: 'v'))

      h = HTML.new
      expect(h.write_to).to eq('<html />')
      h.prefix = '<?xml version="1.0"?>'
      expect(h.write_to).to eq(%[<?xml version="1.0"?>\n<html />])
    end

    it 'HEAD' do
      expect(HEAD.new.name).to eq(:head)
      expect(XDSL.head).to be_kind_of(HEAD)
      expect(OpenDSL.head).to be_kind_of(HEAD)
    end

    it 'META' do
      expect(META.new.name).to eq(:meta)
      expect(XDSL.meta).to be_kind_of(META)
      expect(OpenDSL.meta).to be_kind_of(META)
    end

    it 'LINK' do
      expect(LINK.new.name).to eq(:link)
      expect(XDSL.link).to be_kind_of(LINK)
      expect(OpenDSL.link).to be_kind_of(LINK)
    end

    it 'STYLE' do
      expect(STYLE.new.name).to eq(:style)
      expect(XDSL.style).to be_kind_of(STYLE)
      expect(OpenDSL.style).to be_kind_of(STYLE)
    end

    it 'IMG' do
      expect(IMG.new.name).to eq(:img)
      expect(XDSL.img).to be_kind_of(IMG)
      expect(OpenDSL.img).to be_kind_of(IMG)
    end

    it 'SCRIPT' do
      expect(SCRIPT.new.name).to eq(:script)
      expect(XDSL.script).to be_kind_of(SCRIPT)
      expect(OpenDSL.script).to be_kind_of(SCRIPT)
    end

    it 'TITLE' do
      expect(TITLE.new.name).to eq(:title)
      expect(XDSL.title).to be_kind_of(TITLE)
      expect(OpenDSL.title).to be_kind_of(TITLE)
    end

    it 'BODY' do
      expect(BODY.new.name).to eq(:body)
      expect(XDSL.body).to be_kind_of(BODY)
      expect(OpenDSL.body).to be_kind_of(BODY)
    end

    it 'PRE' do
      expect(PRE.new.name).to eq(:pre)
      expect(XDSL.pre).to be_kind_of(PRE)
      expect(OpenDSL.pre).to be_kind_of(PRE)
    end

    it 'Hn' do
      h1 = Hn.new(1)
      h6 = Hn.new(6)
      expect(h1.name).to eq(:h1)
      expect(h1).to be_kind_of(H1)
      expect(h6.name).to eq(:h6)
      expect(h6).to be_kind_of(H6)
      expect { Hn.new(7) }.to raise_error(ArgumentError)
      expect { Hn.new(0) }.to raise_error(ArgumentError)

      h = Hn.new(1, key: :value) do |hn|
        hn << 'test'
      end
      expect(h[:key]).to eq(:value)
      expect(h[0]).to eq('test')

      [
        [H1, XDSL.h1, OpenDSL.h1],
        [H2, XDSL.h2, OpenDSL.h2],
        [H3, XDSL.h3, OpenDSL.h3],
        [H4, XDSL.h4, OpenDSL.h4],
        [H5, XDSL.h5, OpenDSL.h5],
        [H6, XDSL.h6, OpenDSL.h6]
      ].each do |klass, dsl, od|
        expect(dsl).to be_kind_of(klass)
        expect(od).to be_kind_of(klass)
      end
    end

    it 'P' do
      expect(P.new.name).to eq(:p)
      expect(XDSL.p).to be_kind_of(P)
      expect(OpenDSL.p).to be_kind_of(P)
    end

    it 'A' do
      expect(A.new.name).to eq(:a)
      expect(XDSL.a).to be_kind_of(A)
      expect(OpenDSL.a).to be_kind_of(A)
    end

    it 'EM' do
      expect(EM.new.name).to eq(:em)
      expect(XDSL.em).to be_kind_of(EM)
      expect(OpenDSL.em).to be_kind_of(EM)
    end

    it 'STRONG' do
      expect(STRONG.new.name).to eq(:strong)
      expect(XDSL.strong).to be_kind_of(STRONG)
      expect(OpenDSL.strong).to be_kind_of(STRONG)
    end

    it 'DIV' do
      expect(DIV.new.name).to eq(:div)
      expect(XDSL.div).to be_kind_of(DIV)
      expect(OpenDSL.div).to be_kind_of(DIV)
    end

    it 'SPAN' do
      expect(SPAN.new.name).to eq(:span)
      expect(XDSL.span).to be_kind_of(SPAN)
      expect(OpenDSL.span).to be_kind_of(SPAN)
    end

    it 'UL' do
      expect(UL.new.name).to eq(:ul)
      expect(XDSL.ul).to be_kind_of(UL)
      expect(OpenDSL.ul).to be_kind_of(UL)
    end

    it 'OL' do
      expect(OL.new.name).to eq(:ol)
      expect(XDSL.ol).to be_kind_of(OL)
      expect(OpenDSL.ol).to be_kind_of(OL)
    end

    it 'LI' do
      expect(LI.new.name).to eq(:li)
      expect(XDSL.li).to be_kind_of(LI)
      expect(OpenDSL.li).to be_kind_of(LI)
    end

    it 'DL' do
      expect(DL.new.name).to eq(:dl)
      expect(XDSL.dl).to be_kind_of(DL)
      expect(OpenDSL.dl).to be_kind_of(DL)
    end

    it 'DT' do
      expect(DT.new.name).to eq(:dt)
      expect(XDSL.dt).to be_kind_of(DT)
      expect(OpenDSL.dt).to be_kind_of(DT)
    end

    it 'DD' do
      expect(DD.new.name).to eq(:dd)
      expect(XDSL.dd).to be_kind_of(DD)
      expect(OpenDSL.dd).to be_kind_of(DD)
    end

    it 'TABLE' do
      expect(TABLE.new.name).to eq(:table)
      expect(XDSL.table).to be_kind_of(TABLE)
      expect(OpenDSL.table).to be_kind_of(TABLE)
    end

    it 'CAPTION' do
      expect(CAPTION.new.name).to eq(:caption)
      expect(XDSL.caption).to be_kind_of(CAPTION)
      expect(OpenDSL.caption).to be_kind_of(CAPTION)
    end

    it 'TR' do
      expect(TR.new.name).to eq(:tr)
      expect(XDSL.tr).to be_kind_of(TR)
      expect(OpenDSL.tr).to be_kind_of(TR)
    end

    it 'TH' do
      expect(TH.new.name).to eq(:th)
      expect(XDSL.th).to be_kind_of(TH)
      expect(OpenDSL.th).to be_kind_of(TH)
    end

    it 'TD' do
      expect(TD.new.name).to eq(:td)
      expect(XDSL.td).to be_kind_of(TD)
      expect(OpenDSL.td).to be_kind_of(TD)
    end

    it 'FORM' do
      expect(FORM.new.name).to eq(:form)
      expect(XDSL.form).to be_kind_of(FORM)
      expect(OpenDSL.form).to be_kind_of(FORM)

      expect(FORM.new).not_to include(HIDDEN)
    end

    it 'FORM.new should be able to receive CGI::Session object and set random token' do
      s = double('session')
      h = {}
      expect(s).to receive(:[]).at_least(1).times
      expect(s).to(receive(:[]=).at_least(1).times) { |k, v| h[k] = v }
      f = FORM.new(session: s)
      expect(h['token'].size).to eq(40)
      expect(h['token']).to match(/\A[0-9a-f]{40}\z/)
      expect(f).to include(HIDDEN.new(name: 'token', value: h['token']))

      s = double('session')
      h = {}
      expect(s).to(receive(:[]).at_least(1).times)
      expect(s).to(receive(:[]=).at_least(1).times) { |k, v| h[k] = v }
      f = FORM.new(session: s, session_name: 'random_key')
      expect(h['token']).to be_nil
      expect(h['random_key'].size).to eq(40)
      expect(h['random_key']).to match(/\A[0-9a-f]{40}\z/)
      expect(f).to include(HIDDEN.new(name: 'random_key', value: h['random_key']))

      s = double('session')
      h = {}
      expect(s).to(receive(:[]).at_least(1).times) { |k| h[k] }
      expect(s).to(receive(:[]=).at_least(1).times) { |k, v| h[k] = v }
      FORM.new(session: s)
      token = s['token']
      expect(FORM.new(session: s)).to include(HIDDEN.new(name: 'token', value: token))
      expect(s['token']).to eq(token)
    end

    it 'TEXTAREA' do
      expect(TEXTAREA.new(name: 'item')).to eq(Element.new(:textarea, name: 'item'))
      expect(TEXTAREA.new(name: :item)).to eq(Element.new(:textarea, name: :item))
      expect(TEXTAREA.new(name: 'item', class: 'cv')).to eq(Element.new(:textarea, name: 'item', class: 'cv'))

      t = XDSL.textarea(name: 't')
      expect(t).to be_kind_of(TEXTAREA)
      expect(t[:name]).to eq('t')

      t = OpenDSL.textarea(name: 't')
      expect(t).to be_kind_of(TEXTAREA)
      expect(t[:name]).to eq('t')
    end

    it 'BUTTON' do
      expect(BUTTON.new).to eq(Element.new(:button))
    end

    it 'INPUT' do
      expect(INPUT.new(type: :test, name: :item, value: 'v')).to eq(Element.new(:input, type: :test, name: :item, value: 'v'))
      expect(INPUT.new(type: 'test', name: 'item', value: 'v')).to eq(Element.new(:input, type: 'test', name: 'item', value: 'v'))
      expect(INPUT.new(type: :test, name: :item, value: 'v', class: 'c')).to eq(Element.new(:input, type: :test, name: :item, value: 'v', class: 'c'))

      expect(INPUT.new(type: :submit, value: 'v')).to eq(Element.new(:input, type: :submit, value: 'v'))
      expect(INPUT.new(type: :submit, name: 'item')).to eq(Element.new(:input, type: :submit, name: 'item'))

      i = XDSL.input(type: :dummy, name: :n, value: :v)
      expect(i).to be_kind_of(INPUT)
      expect(i).to match(INPUT.new(type: :dummy, name: :n, value: :v))

      i = OpenDSL.input(type: :dummy, name: :n, value: :v)
      expect(i).to be_kind_of(INPUT)
      expect(i).to eq(INPUT.new(type: :dummy, name: :n, value: :v))
    end

    it 'HIDDEN' do
      expect(HIDDEN.new(name: 'item', value: 'v')).to eq(Element.new(:input, type: :hidden, name: 'item', value: 'v'))
      expect(HIDDEN.new(name: :item, value: 'v')).to eq(Element.new(:input, type: :hidden, name: :item, value: 'v'))
      expect(HIDDEN.new(name: :item, value: 'v', class: 'c')).to eq(Element.new(:input, type: :hidden, name: :item, value: 'v', class: 'c'))

      h = XDSL.hidden(name: :n, value: :v)
      expect(h).to be_kind_of(HIDDEN)
      expect(h).to match(HIDDEN.new(name: :n, value: :v))

      h = OpenDSL.hidden(name: :n, value: :v)
      expect(h).to be_kind_of(HIDDEN)
      expect(h).to eq(HIDDEN.new(name: :n, value: :v))
    end

    it 'SUBMIT' do
      expect(SUBMIT.new).to eq(Element.new(:button, type: :submit))
      expect(SUBMIT.new(value: 'OK')).to eq(Element.new(:button, type: :submit, value: 'OK'))
      expect(SUBMIT.new(value: 'OK', class: 'c')).to eq(Element.new(:button, type: :submit, value: 'OK', class: 'c'))
      opt = { value: 'v', name: 'n' }
      opt2 = opt.dup
      SUBMIT.new(opt2)
      expect(opt2).to eq(opt)

      s = XDSL.submit
      expect(s).to be_kind_of(SUBMIT)
      expect(s).to match(SUBMIT.new)
      expect(!s[:name]).to be true
      expect(!s[:value]).to be true
      s = XDSL.submit(name: :s, value: :v)
      expect(s[:name]).to eq(:s)
      expect(s[:value]).to eq(:v)

      s = OpenDSL.submit
      expect(s).to be_kind_of(SUBMIT)
      expect(s).to eq(SUBMIT.new)
      expect(s[:name]).to be_nil
      expect(s[:value]).to be_nil
      s = OpenDSL.submit(name: :s, value: :v)
      expect(s).to eq(SUBMIT.new(name: :s, value: :v))
    end

    it 'TEXT' do
      expect(TEXT.new(name: :item)).to eq(Element.new(:input, type: :text, name: :item))
      expect(TEXT.new(name: 'item')).to eq(Element.new(:input, type: :text, name: 'item'))
      expect(TEXT.new(name: :item, value: 'txt')).to eq(Element.new(:input, type: :text, name: :item, value: 'txt'))
      expect(TEXT.new(name: :item, value: 'txt', class: 'c')).to eq(Element.new(:input, type: :text, name: :item, value: 'txt', class: 'c'))

      t = XDSL.text(name: :n, value: :v)
      expect(t).to be_kind_of(TEXT)
      expect(t).to match(TEXT.new(name: :n, value: :v))

      t = OpenDSL.text(name: :n, value: :v)
      expect(t).to be_kind_of(TEXT)
      expect(t).to eq(TEXT.new(name: :n, value: :v))
    end

    it 'PASSWORD' do
      expect(PASSWORD.new(name: :item)).to eq(Element.new(:input, type: :password, name: :item))
      expect(PASSWORD.new(name: 'item')).to eq(Element.new(:input, type: :password, name: 'item'))
      expect(PASSWORD.new(name: :item, value: 'txt')).to eq(Element.new(:input, type: :password, name: :item, value: 'txt'))
      expect(PASSWORD.new(name: :item, value: 'txt', class: 'c')).to eq(Element.new(:input, type: :password, name: :item, value: 'txt', class: 'c'))

      t = XDSL.password(name: :n, value: :v)
      expect(t).to be_kind_of(PASSWORD)
      expect(t).to match(PASSWORD.new(name: :n, value: :v))

      t = OpenDSL.password(name: :n, value: :v)
      expect(t).to be_kind_of(PASSWORD)
      expect(t).to eq(PASSWORD.new(name: :n, value: :v))
    end

    it 'FILE' do
      expect(FILE.new(name: :foo)).to eq(Element.new(:input, type: :file, name: :foo))
      expect(XDSL.file(name: :foo)).to match(FILE.new(name: :foo))

      expect(OpenDSL.file(name: :foo)).to eq(FILE.new(name: :foo))
    end

    it 'SELECT' do
      expect(SELECT.new(name: :foo)).to eq(Element.new(:select, name: :foo))
      expect(XDSL.select(name: :foo)).to eq(SELECT.new(name: :foo))

      expect(OpenDSL.select(name: :foo)).to eq(SELECT.new(name: :foo))
    end

    it 'OPTION' do
      expect(OPTION.new(value: :bar, selected: true) { |e| e << 'TEXT' }).to eq(Element.new(:option, value: :bar, selected: true) { |e| e.add('TEXT') })
      expect(XDSL.option(value: :bar)).to eq(OPTION.new(value: :bar))

      expect(OpenDSL.option(value: :bar)).to eq(OPTION.new(value: :bar))
    end

    it 'BR' do
      expect(BR.new.name).to eq(:br)
      expect(XDSL.br).to be_kind_of(BR)
      expect(OpenDSL.br).to be_kind_of(BR)
    end

    it 'HR' do
      expect(HR.new.name).to eq(:hr)
      expect(XDSL.hr).to be_kind_of(HR)
      expect(OpenDSL.hr).to be_kind_of(HR)
    end
  end

  describe EimXML::XHTML::OpenDSL do
    it 'replace EimXML::XHTML::DSL' do
      e = EimXML::XHTML::OpenDSL.html do |d|
        d.head do
          d.title.add 'Title'
        end
        d.body do
          d.h1.add 'Sample'
          d.p do
            d.add 'text'
            d.add 'next'
          end
        end
      end
      expect(e).to eq(EimXML::XHTML::DSL.html do
        head do
          title.add 'Title'
        end
        body do
          h1.add 'Sample'
          p do
            add 'text'
            add 'next'
          end
        end
      end)
    end
  end

  describe EimXML::XHTML::Formatter do
    describe '#write' do
      it 'should set :preservers=>PRESERVE_SPACES to default option' do
        e = EimXML::XHTML::HTML.new
        expect(EimXML::Formatter).to receive(:write).with(e, preservers: EimXML::XHTML::PRESERVE_SPACES, opt: :dummy)
        EimXML::XHTML::Formatter.write(e, opt: :dummy)
      end

      it 'should return string' do
        h = EimXML::XHTML::DSL.html do
          head do
            style.add("style\ntext")
            script.add("script\ntext")
          end
          body do
            div.add("text\nin\ndiv")
            pre.add("pre\nt")
            h1.add("1\nt")
            h2.add("2\nt")
            h3.add("3\nt")
            h4.add("4\nt")
            h5.add("5\nt")
            h6.add("6\nt")
            p.add("p\nt")
            a.add("a\nt")
            em.add("e\nt")
            strong.add("s\nt")
            span.add("sp\nt")
            li.add("li\nt")
            dt.add("dt\nt")
            dd.add("dd\nt")
            caption.add("c\nt")
            th.add("th\nt")
            td.add("td\nt")
            button.add("button\nt")
          end
        end

        s = <<~XML
          <html>
            <head>
              <style>style
          text</style>
              <script>script
          text</script>
            </head>
            <body>
              <div>
                text
                in
                div
              </div>
              <pre>pre
          t</pre>
              <h1>1
          t</h1>
              <h2>2
          t</h2>
              <h3>3
          t</h3>
              <h4>4
          t</h4>
              <h5>5
          t</h5>
              <h6>6
          t</h6>
              <p>p
          t</p>
              <a>a
          t</a>
              <em>e
          t</em>
              <strong>s
          t</strong>
              <span>sp
          t</span>
              <li>li
          t</li>
              <dt>dt
          t</dt>
              <dd>dd
          t</dd>
              <caption>c
          t</caption>
              <th>th
          t</th>
              <td>td
          t</td>
              <button>button
          t</button>
            </body>
          </html>
        XML
        expect(EimXML::XHTML::Formatter.write(h)).to eq(s)
      end
    end
  end
end
