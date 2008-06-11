require "stringio"
require "eim_xml/xhtml"

class << Object.new
	include EimXML
	include EimXML::XHTML

	describe XHTML do
		it "DSL.base_ should raise NoMethodError" do
			lambda{DSL.base_}.should raise_error(NoMethodError)
		end

		it "HTML" do
			h = HTML.new(:attr=>"value")
			h.should == Element.new(:html, :attr=>"value")

			h = HTML.new do |e|
				e <<= Element.new(:sub)
			end
			h2 = HTML.new
			h2 << Element.new(:sub)
			h2.should == h

			lambda{EimXML::DSL.html}.should raise_error(NoMethodError)
			DSL.html(:key=>"v").should == HTML.new(:key=>"v")
			OpenDSL.html(:key=>"v").should == HTML.new(:key=>"v")

			h = HTML.new
			h.to_xml.should == "<html />"
			h.prefix='<?xml version="1.0"?>'
			h.to_xml.should == %[<?xml version="1.0"?>\n<html />]
		end

		it "HEAD" do
			HEAD.new.name.should == :head
			DSL.head.should be_kind_of(HEAD)
			OpenDSL.head.should be_kind_of(HEAD)
		end

		it "META" do
			META.new.name.should == :meta
			DSL.meta.should be_kind_of(META)
			OpenDSL.meta.should be_kind_of(META)
		end

		it "LINK" do
			LINK.new.name.should == :link
			DSL.link.should be_kind_of(LINK)
			OpenDSL.link.should be_kind_of(LINK)
		end

		it "STYLE" do
			STYLE.new.name.should == :style
			DSL.style.should be_kind_of(STYLE)
			OpenDSL.style.should be_kind_of(STYLE)
		end

		it "SCRIPT" do
			SCRIPT.new.name.should == :script
			DSL.script.should be_kind_of(SCRIPT)
			OpenDSL.script.should be_kind_of(SCRIPT)
		end

		it "TITLE" do
			TITLE.new.name.should == :title
			DSL.title.should be_kind_of(TITLE)
			OpenDSL.title.should be_kind_of(TITLE)
		end

		it "BODY" do
			BODY.new.name.should == :body
			DSL.body.should be_kind_of(BODY)
			OpenDSL.body.should be_kind_of(BODY)
		end

		it "PRE" do
			PRE.new.name.should == :pre
			DSL.pre.should be_kind_of(PRE)
			OpenDSL.pre.should be_kind_of(PRE)
			PRE.new.hold_space?.should be_true
		end

		it "Hn" do
			h1 = Hn.new(1)
			h6 = Hn.new(6)
			h1.name.should == :h1
			h1.should be_kind_of(H1)
			h6.name.should == :h6
			h6.should be_kind_of(H6)
			lambda{Hn.new(7)}.should raise_error(ArgumentError)
			lambda{Hn.new(0)}.should raise_error(ArgumentError)

			h = Hn.new(1, :key=>:value) do |hn|
				hn << "test"
			end
			h[:key].should == :value
			h[0].should == "test"

			[
				[H1, DSL.h1, OpenDSL.h1],
				[H2, DSL.h2, OpenDSL.h2],
				[H3, DSL.h3, OpenDSL.h3],
				[H4, DSL.h4, OpenDSL.h4],
				[H5, DSL.h5, OpenDSL.h5],
				[H6, DSL.h6, OpenDSL.h6]
			].each do |klass, dsl, od|
				dsl.should be_kind_of(klass)
				od.should be_kind_of(klass)
			end
		end

		it "P" do
			P.new.name.should == :p
			DSL.p.should be_kind_of(P)
			OpenDSL.p.should be_kind_of(P)
		end

		it "A" do
			A.new.name.should == :a
			DSL.a.should be_kind_of(A)
			OpenDSL.a.should be_kind_of(A)
		end

		it "EM" do
			EM.new.name.should == :em
			DSL.em.should be_kind_of(EM)
			OpenDSL.em.should be_kind_of(EM)
		end

		it "STRONG" do
			STRONG.new.name.should == :strong
			DSL.strong.should be_kind_of(STRONG)
			OpenDSL.strong.should be_kind_of(STRONG)
		end

		it "DIV" do
			DIV.new.name.should == :div
			DSL.div.should be_kind_of(DIV)
			OpenDSL.div.should be_kind_of(DIV)
		end

		it "UL" do
			UL.new.name.should == :ul
			DSL.ul.should be_kind_of(UL)
			OpenDSL.ul.should be_kind_of(UL)
		end

		it "OL" do
			OL.new.name.should == :ol
			DSL.ol.should be_kind_of(OL)
			OpenDSL.ol.should be_kind_of(OL)
		end

		it "LI" do
			LI.new.name.should == :li
			DSL.li.should be_kind_of(LI)
			OpenDSL.li.should be_kind_of(LI)
		end

		it "DL" do
			DL.new.name.should == :dl
			DSL.dl.should be_kind_of(DL)
			OpenDSL.dl.should be_kind_of(DL)
		end

		it "DT" do
			DT.new.name.should == :dt
			DSL.dt.should be_kind_of(DT)
			OpenDSL.dt.should be_kind_of(DT)
		end

		it "DD" do
			DD.new.name.should == :dd
			DSL.dd.should be_kind_of(DD)
			OpenDSL.dd.should be_kind_of(DD)
		end

		it "TABLE" do
			TABLE.new.name.should == :table
			DSL.table.should be_kind_of(TABLE)
			OpenDSL.table.should be_kind_of(TABLE)
		end

		it "CAPTION" do
			CAPTION.new.name.should == :caption
			DSL.caption.should be_kind_of(CAPTION)
			OpenDSL.caption.should be_kind_of(CAPTION)
		end

		it "TR" do
			TR.new.name.should == :tr
			DSL.tr.should be_kind_of(TR)
			OpenDSL.tr.should be_kind_of(TR)
		end

		it "TH" do
			TH.new.name.should == :th
			DSL.th.should be_kind_of(TH)
			OpenDSL.th.should be_kind_of(TH)
		end

		it "TD" do
			TD.new.name.should == :td
			DSL.td.should be_kind_of(TD)
			OpenDSL.td.should be_kind_of(TD)
		end

		it "FORM" do
			FORM.new.name.should == :form
			DSL.form.should be_kind_of(FORM)
			OpenDSL.form.should be_kind_of(FORM)

			FORM.new.should_not include(HIDDEN)
		end

		it "FORM.new should be able to receive CGI::Session object and set random token" do
			s = mock("session")
			h = {}
			s.should_receive(:[]).any_number_of_times{|k| h[k]}
			s.should_receive(:[]=).any_number_of_times{|k, v| h[k]=v}
			f = FORM.new(:session=>s)
			h["token"].size.should == 40
			h["token"].should =~ /\A[0-9a-f]{40}\z/
			f.should include(HIDDEN.new(:name=>"token", :value=>h["token"]))

			s = mock("session")
			h = {}
			s.should_receive(:[]).any_number_of_times{|k| h[k]}
			s.should_receive(:[]=).any_number_of_times{|k, v| h[k]=v}
			f = FORM.new(:session=>s, :session_name=>"random_key")
			h["token"].should be_nil
			h["random_key"].size.should == 40
			h["random_key"].should =~ /\A[0-9a-f]{40}\z/
			f.should include(HIDDEN.new(:name=>"random_key", :value=>h["random_key"]))

			s = mock("session")
			h = {}
			s.should_receive(:[]).any_number_of_times{|k| h[k]}
			s.should_receive(:[]=).any_number_of_times{|k, v| h[k]=v}
			FORM.new(:session=>s)
			token = s["token"]
			FORM.new(:session=>s).should include(HIDDEN.new(:name=>"token", :value=>token))
			s["token"].should == token
		end

		it "TEXTAREA" do
			TEXTAREA.new(:name=>"item").should == Element.new(:textarea, :name=>"item")
			TEXTAREA.new(:name=>:item).should == Element.new(:textarea, :name=>:item)
			TEXTAREA.new(:name=>"item", :class=>"cv").should == Element.new(:textarea, :name=>"item", :class=>"cv")

			t = DSL.textarea(:name=>"t")
			t.should be_kind_of(TEXTAREA)
			t[:name].should == "t"

			t = OpenDSL.textarea(:name=>"t")
			t.should be_kind_of(TEXTAREA)
			t[:name].should == "t"
		end

		it "INPUT" do
			INPUT.new(:type=>:test, :name=>:item, :value=>"v").should == Element.new(:input, :type=>:test, :name=>:item, :value=>"v")
			INPUT.new(:type=>"test", :name=>"item", :value=>"v").should == Element.new(:input, :type=>"test", :name=>"item", :value=>"v")
			INPUT.new(:type=>:test, :name=>:item, :value=>"v", :class=>"c").should == Element.new(:input, :type=>:test, :name=>:item, :value=>"v", :class=>"c")

			INPUT.new(:type=>:submit, :value=>"v").should == Element.new(:input, :type=>:submit, :value=>"v")
			INPUT.new(:type=>:submit, :name=>"item").should == Element.new(:input, :type=>:submit, :name=>"item")

			i = DSL.input(:type=>:dummy, :name=>:n, :value=>:v)
			i.should be_kind_of(INPUT)
			i.should =~ INPUT.new(:type=>:dummy, :name=>:n, :value=>:v)

			i = OpenDSL.input(:type=>:dummy, :name=>:n, :value=>:v)
			i.should be_kind_of(INPUT)
			i.should == INPUT.new(:type=>:dummy, :name=>:n, :value=>:v)
		end

		it "HIDDEN" do
			HIDDEN.new(:name=>"item", :value=>"v").should == Element.new(:input, :type=>:hidden, :name=>"item", :value=>"v")
			HIDDEN.new(:name=>:item, :value=>"v").should == Element.new(:input, :type=>:hidden, :name=>:item, :value=>"v")
			HIDDEN.new(:name=>:item, :value=>"v", :class=>"c").should == Element.new(:input, :type=>:hidden, :name=>:item, :value=>"v", :class=>"c")

			h = DSL.hidden(:name=>:n, :value=>:v)
			h.should be_kind_of(HIDDEN)
			h.should =~ HIDDEN.new(:name=>:n, :value=>:v)

			h = OpenDSL.hidden(:name=>:n, :value=>:v)
			h.should be_kind_of(HIDDEN)
			h.should == HIDDEN.new(:name=>:n, :value=>:v)
		end

		it "SUBMIT" do
			SUBMIT.new.should == Element.new(:input, :type=>:submit)
			SUBMIT.new(:value=>"OK").should == Element.new(:input, :type=>:submit, :value=>"OK")
			SUBMIT.new(:value=>"OK", :class=>"c").should == Element.new(:input, :type=>:submit, :value=>"OK", :class=>"c")
			opt = {:value=>"v", :name=>"n"}
			opt2 = opt.dup
			SUBMIT.new(opt2)
			opt2.should == opt

			s = DSL.submit
			s.should be_kind_of(SUBMIT)
			s.should =~ SUBMIT.new
			(!s[:name]).should be_true
			(!s[:value]).should be_true
			s = DSL.submit(:name=>:s, :value=>:v)
			s[:name].should == :s
			s[:value].should == :v

			s = OpenDSL.submit
			s.should be_kind_of(SUBMIT)
			s.should == SUBMIT.new
			s[:name].should be_nil
			s[:value].should be_nil
			s = OpenDSL.submit(:name=>:s, :value=>:v)
			s.should == SUBMIT.new(:name=>:s, :value=>:v)
		end

		it "TEXT" do
			TEXT.new(:name=>:item).should == Element.new(:input, :type=>:text, :name=>:item)
			TEXT.new(:name=>"item").should == Element.new(:input, :type=>:text, :name=>"item")
			TEXT.new(:name=>:item, :value=>"txt").should == Element.new(:input, :type=>:text, :name=>:item, :value=>"txt")
			TEXT.new(:name=>:item, :value=>"txt", :class=>"c").should == Element.new(:input, :type=>:text, :name=>:item, :value=>"txt", :class=>"c")

			t = DSL.text(:name=>:n, :value=>:v)
			t.should be_kind_of(TEXT)
			t.should =~ TEXT.new(:name=>:n, :value=>:v)

			t = OpenDSL.text(:name=>:n, :value=>:v)
			t.should be_kind_of(TEXT)
			t.should == TEXT.new(:name=>:n, :value=>:v)
		end

		it "PASSWORD" do
			PASSWORD.new(:name=>:item).should == Element.new(:input, :type=>:password, :name=>:item)
			PASSWORD.new(:name=>"item").should == Element.new(:input, :type=>:password, :name=>"item")
			PASSWORD.new(:name=>:item, :value=>"txt").should == Element.new(:input, :type=>:password, :name=>:item, :value=>"txt")
			PASSWORD.new(:name=>:item, :value=>"txt", :class=>"c").should == Element.new(:input, :type=>:password, :name=>:item, :value=>"txt", :class=>"c")

			t = DSL.password(:name=>:n, :value=>:v)
			t.should be_kind_of(PASSWORD)
			t.should =~ PASSWORD.new(:name=>:n, :value=>:v)

			t = OpenDSL.password(:name=>:n, :value=>:v)
			t.should be_kind_of(PASSWORD)
			t.should == PASSWORD.new(:name=>:n, :value=>:v)
		end

		it "BR" do
			BR.new.name.should == :br
			DSL.br.should be_kind_of(BR)
			OpenDSL.br.should be_kind_of(BR)
		end

		it "HR" do
			HR.new.name.should == :hr
			DSL.hr.should be_kind_of(HR)
			OpenDSL.hr.should be_kind_of(HR)
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
end
