# Test for eim_xml/xhtml.rb
#
# Copyright (C) 2007, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.

require "eim_xml/xhtml"
require "eim_xml/assertions"
require "test/unit"
require "stringio"

class XHTMLTest < Test::Unit::TestCase
	include EimXML::XHTML
	include EimXML::Assertions
	Element = EimXML::Element

	def test_base_
		assert_raise(NoMethodError){DSL.base_}
	end

	def setup
		@od = OpenDSL.new
	end

	def test_html
		h = HTML.new(:attr=>"value")
		assert_equal(Element.new(:html, :attr=>"value"), h)

		h = HTML.new do |e|
			e <<= Element.new(:sub)
		end
		h2 = HTML.new
		h2 << Element.new(:sub)
		assert_equal(h, h2)

		assert_raise(NoMethodError){EimXML::DSL.html}
		assert_match(HTML.new(:key=>"v"), DSL.html(:key=>"v"))
		@od.html(:key=>"v").should == HTML.new(:key=>"v")

		h = HTML.new
		h.to_xml.should == "<html />"
		h.prefix='<?xml version="1.0"?>'
		h.to_xml.should == %[<?xml version="1.0"?>\n<html />]
	end

	def test_head
		assert_equal(:head, HEAD.new.name)
		assert_kind_of(HEAD, DSL.head)
		@od.head.should be_kind_of(HEAD)
	end

	def test_meta
		assert_equal(:meta, META.new.name)
		assert_kind_of(META, DSL.meta)
		@od.meta.should be_kind_of(META)
	end

	def test_link
		assert_equal(:link, LINK.new.name)
		assert_kind_of(LINK, DSL.link)
		@od.link.should be_kind_of(LINK)
	end

	def test_style
		assert_equal(:style, STYLE.new.name)
		assert_kind_of(STYLE, DSL.style)
		@od.style.should be_kind_of(STYLE)
	end

	def test_script
		assert_equal(:script, SCRIPT.new.name)
		assert_kind_of(SCRIPT, DSL.script)
		@od.script.should be_kind_of(SCRIPT)
	end

	def test_title
		assert_equal(:title, TITLE.new.name)
		assert_kind_of(TITLE, DSL.title)
		@od.title.should be_kind_of(TITLE)
	end

	def test_body
		assert_equal(:body, BODY.new.name)
		assert_kind_of(BODY, DSL.body)
		@od.body.should be_kind_of(BODY)
	end

	def test_pre
		assert_equal(:pre, PRE.new.name)
		assert_kind_of(PRE, DSL.pre)
		@od.pre.should be_kind_of(PRE)
		PRE.new.hold_space?.should be_true
	end

	def test_hn
		h1 = Hn.new(1)
		h6 = Hn.new(6)
		assert_equal(:h1, h1.name)
		assert_kind_of(H1, h1)
		assert_equal(:h6, h6.name)
		assert_kind_of(H6, h6)
		assert_raises(ArgumentError){Hn.new(7)}
		assert_raises(ArgumentError){Hn.new(0)}

		h = Hn.new(1, :key=>:value) do |hn|
			hn << "test"
		end
		assert_equal(:value, h[:key])
		assert_equal("test", h[0])

		[
			[H1, DSL.h1, @od.h1],
			[H2, DSL.h2, @od.h2],
			[H3, DSL.h3, @od.h3],
			[H4, DSL.h4, @od.h4],
			[H5, DSL.h5, @od.h5],
			[H6, DSL.h6, @od.h6]
		].each do |klass, dsl, od|
			dsl.should be_kind_of(klass)
			od.should be_kind_of(klass)
		end
	end

	def test_p
		assert_equal(:p, P.new.name)
		assert_kind_of(P, DSL.p)
		@od.p.should be_kind_of(P)
	end

	def test_a
		assert_equal(:a, A.new.name)
		assert_kind_of(A, DSL.a)
		@od.a.should be_kind_of(A)
	end

	def test_em
		assert_equal(:em, EM.new.name)
		assert_kind_of(EM, DSL.em)
		@od.em.should be_kind_of(EM)
	end

	def test_strong
		assert_equal(:strong, STRONG.new.name)
		assert_kind_of(STRONG, DSL.strong)
		@od.strong.should be_kind_of(STRONG)
	end

	def test_div
		assert_equal(:div, DIV.new.name)
		assert_kind_of(DIV, DSL.div)
		@od.div.should be_kind_of(DIV)
	end

	def test_ul
		assert_equal(:ul, UL.new.name)
		assert_kind_of(UL, DSL.ul)
		@od.ul.should be_kind_of(UL)
	end

	def test_ol
		assert_equal(:ol, OL.new.name)
		assert_kind_of(OL, DSL.ol)
		@od.ol.should be_kind_of(OL)
	end

	def test_li
		assert_equal(:li, LI.new.name)
		assert_kind_of(LI, DSL.li)
		@od.li.should be_kind_of(LI)
	end

	def test_dl
		DL.new.name.should == :dl
		DSL.dl.should be_kind_of(DL)
		@od.dl.should be_kind_of(DL)
	end

	def test_dt
		DT.new.name.should == :dt
		DSL.dt.should be_kind_of(DT)
		@od.dt.should be_kind_of(DT)
	end

	def test_dd
		DD.new.name.should == :dd
		DSL.dd.should be_kind_of(DD)
		@od.dd.should be_kind_of(DD)
	end

	def test_table
		assert_equal(:table, TABLE.new.name)
		assert_kind_of(TABLE, DSL.table)
		@od.table.should be_kind_of(TABLE)
	end

	def test_caption
		assert_equal(:caption, CAPTION.new.name)
		assert_kind_of(CAPTION, DSL.caption)
		@od.caption.should be_kind_of(CAPTION)
	end

	def test_tr
		assert_equal(:tr, TR.new.name)
		assert_kind_of(TR, DSL.tr)
		@od.tr.should be_kind_of(TR)
	end

	def test_th
		assert_equal(:th, TH.new.name)
		assert_kind_of(TH, DSL.th)
		@od.th.should be_kind_of(TH)
	end

	def test_td
		assert_equal(:td, TD.new.name)
		assert_kind_of(TD, DSL.td)
		@od.td.should be_kind_of(TD)
	end

	def test_form
		assert_equal(:form, FORM.new.name)
		assert_kind_of(FORM, DSL.form)
		@od.form.should be_kind_of(FORM)
	end

	def test_text_area
		assert_equal(Element.new(:textarea, :name=>"item"), TEXTAREA.new("item"))
		assert_equal(Element.new(:textarea, :name=>:item), TEXTAREA.new(:item))
		assert_equal(Element.new(:textarea, :name=>"item", :class=>"cv"), TEXTAREA.new("item", :class=>"cv"))

		t = DSL.textarea("t")
		assert_kind_of(TEXTAREA, t)
		assert_equal("t", t[:name])

		t = @od.textarea("t")
		t.should be_kind_of(TEXTAREA)
		t[:name].should == "t"
	end

	def test_input
		assert_equal(Element.new(:input, :type=>:test, :name=>:item, :value=>"v"), INPUT.new(:test, :item, "v"))
		assert_equal(Element.new(:input, :type=>"test", :name=>"item", :value=>"v"), INPUT.new("test", "item", "v"))
		assert_equal(Element.new(:input, :type=>:test, :name=>:item, :value=>"v", :class=>"c"), INPUT.new(:test, :item, "v", :class=>"c"))

		assert_equal(Element.new(:input, :type=>:submit, :value=>"v"), INPUT.new(:submit, nil, "v"))
		assert_equal(Element.new(:input, :type=>:submit, :name=>"item"), INPUT.new(:submit, "item", nil))

		i = DSL.input(:dummy, :n, :v)
		assert_kind_of(INPUT, i)
		assert_match(INPUT.new(:dummy, :n, :v), i)

		i = @od.input(:dummy, :n, :v)
		i.should be_kind_of(INPUT)
		i.should == INPUT.new(:dummy, :n, :v)
	end

	def test_hidden
		assert_equal(Element.new(:input, :type=>:hidden, :name=>"item", :value=>"v"), HIDDEN.new("item", "v"))
		assert_equal(Element.new(:input, :type=>:hidden, :name=>:item, :value=>"v"), HIDDEN.new(:item, "v"))
		assert_equal(Element.new(:input, :type=>:hidden, :name=>:item, :value=>"v", :class=>"c"), HIDDEN.new(:item, "v", :class=>"c"))

		h = DSL.hidden(:n, :v)
		assert_kind_of(HIDDEN, h)
		assert_match(HIDDEN.new(:n, :v), h)

		h = @od.hidden(:n, :v)
		h.should be_kind_of(HIDDEN)
		h.should == HIDDEN.new(:n, :v)
	end

	def test_submit
		assert_equal(Element.new(:input, :type=>:submit), SUBMIT.new)
		assert_equal(Element.new(:input, :type=>:submit, :value=>"OK"), SUBMIT.new(:value=>"OK"))
		assert_equal(Element.new(:input, :type=>:submit, :value=>"OK", :class=>"c"), SUBMIT.new(:value=>"OK", :class=>"c"))
		opt = {:value=>"v", :name=>"n"}
		opt2 = opt.dup
		SUBMIT.new(opt2)
		assert_equal(opt, opt2)

		s = DSL.submit
		assert_kind_of(SUBMIT, s)
		assert_match(SUBMIT.new, s)
		assert(!s[:name])
		assert(!s[:value])
		s = DSL.submit(:name=>:s, :value=>:v)
		assert_equal(:s, s[:name])
		assert_equal(:v, s[:value])

		s = @od.submit
		s.should be_kind_of(SUBMIT)
		s.should == SUBMIT.new
		s[:name].should be_nil
		s[:value].should be_nil
		s = @od.submit(:name=>:s, :value=>:v)
		s.should == SUBMIT.new(:name=>:s, :value=>:v)
	end

	def test_text
		assert_equal(Element.new(:input, :type=>:text, :name=>:item), TEXT.new(:item))
		assert_equal(Element.new(:input, :type=>:text, :name=>"item"), TEXT.new("item"))
		assert_equal(Element.new(:input, :type=>:text, :name=>:item, :value=>"txt"), TEXT.new(:item, "txt"))
		assert_equal(Element.new(:input, :type=>:text, :name=>:item, :value=>"txt", :class=>"c"), TEXT.new(:item, "txt", :class=>"c"))

		t = DSL.text(:n, :v)
		assert_kind_of(TEXT, t)
		assert_match(TEXT.new(:n, :v), t)

		t = @od.text(:n, :v)
		t.should be_kind_of(TEXT)
		t.should == TEXT.new(:n, :v)
	end
end

describe EimXML::XHTML::OpenDSL do
	it "replace EimXML::XHTML::DSL" do
		e = EimXML::XHTML::OpenDSL.html do |d|
			d.head do
				d.title.add "Title"
			end
			d.body do
				d.h1.add "Sample"
				d.p do
					d.add "text"
					d.add "next"
				end
			end
		end
		e.should == EimXML::XHTML::DSL.html do
			head do
				title.add "Title"
			end
			body do
				h1.add "Sample"
				p do
					add "text"
					add "next"
				end
			end
		end
	end
end
