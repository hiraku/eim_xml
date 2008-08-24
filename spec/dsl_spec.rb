require "eim_xml/dsl"

class << Object.new
	include EimXML

	describe DSL do
		it "scope is in instance of DSL" do
			outer = inner = nil
			e3 = e2 = nil
			block_executed = false
			e = DSL.element(:out, :k1=>"v1") do
				outer = self
				e2 = element(:in, :k2=>"v2") do
					block_executed = true
					inner = self
					e3 = element(:deep)
				end
			end

			block_executed.should == true
			outer.should be_kind_of(DSL)
			inner.should be_kind_of(DSL)
			outer.object_id.should == inner.object_id

			e.name.should == :out
			e[:k1].should == "v1"
			e[0].name.should == :in
			e[0][:k2].should == "v2"
			e[0][0].name.should == :deep
			e2.object_id.should == e[0].object_id
			e3.object_id.should == e[0][0].object_id
		end
	end

	describe "Subclass of BaseDSL" do
		class DSL1 < BaseDSL
			register([EimXML::Element, "call"])
			register(Hash)
			register(String, Array, Object)
		end

		it "register" do
			lambda{DSL.call(:dummy)}.should raise_error(NoMethodError)
			lambda{BaseDSL.call(:dummy)}.should raise_error(NoMethodError)
			lambda{DSL1.element(:dummy)}.should raise_error(NoMethodError)
			DSL1.call(:dummy).should be_kind_of(Element)
			DSL1.hash.should be_kind_of(Hash)
			DSL1.string.should be_kind_of(String)
			DSL1.array.should be_kind_of(Array)
			DSL1.object.should be_kind_of(Object)
		end
	end

	describe OpenDSL do
		it "scope of block is one of outside" do
			@scope_checker_variable = 1
			block_executed = false
			d = OpenDSL.new do |d|
				block_executed = true
				d.should be_kind_of(OpenDSL)
				d.container.should be_nil
				d.element(:base, :key1=>"v1") do
					@scope_checker_variable.should == 1
					self.should_not be_kind_of(Element)
					d.container.should be_kind_of(Element)
					d.container.should == Element.new(:base, :key1=>"v1")
					d.element(:sub, :key2=>"v2") do
						d.container.should be_kind_of(Element)
						d.container.should == Element.new(:sub, :key2=>"v2")
					end
					d.element(:sub2).should == Element.new(:sub2)
				end
			end
			block_executed.should be_true
		end

		it "DSL methods return element" do
			d = OpenDSL.new
			d.container.should be_nil
			r = d.element(:base, :key1=>"v1") do
				d.element(:sub, :key2=>"v2")
			end
			r.should == DSL.element(:base, :key1=>"v1") do
				element(:sub, :key2=>"v2")
			end
		end

		it "DSL method's block given instance of OpenDSL" do
			e = OpenDSL.new.element(:base) do |d|
				d.should be_kind_of(OpenDSL)
				d.container.name.should == :base
				d.element(:sub) do |d2|
					d2.object_id.should == d.object_id
				end
			end

			e.should == DSL.element(:base) do
				element(:sub)
			end
		end

		it "ensure reset container when error raised" do
			OpenDSL.new do |d|
				begin
					d.element(:base) do
						begin
							d.element(:sub) do
								raise "OK"
							end
						rescue RuntimeError => e
							raise unless e.message=="OK"
							d.container.name.should == :base
							raise
						end
					end
				rescue RuntimeError => e
					raise unless e.message=="OK"
					d.container.should == nil
				end
			end
		end

		it "respond to add" do
			r = OpenDSL.new.element(:base) do |d|
				d.add "text"
				d.element(:sub) do
					s = Element.new(:sub)
					s.add("sub text")
					d.add("sub text").should == s
				end
			end

			r.should == DSL.element(:base) do
				add "text"
				element(:sub) do
					add "sub text"
				end
			end
		end

		it "respond to <<" do
			r = OpenDSL.new.element(:base) do |d|
				b = Element.new(:base)
				b << "text" << "next"
				(d << "text" << "next").should == b
			end
			r.should == DSL.element(:base) do
				add "text"
				add "next"
			end
		end

		it "can call directly element method" do
			r = OpenDSL.element(:base) do |d|
				d.element(:sub)
				d.element(:sub2)
			end
			r.should == DSL.element(:base) do
				element(:sub)
				element(:sub2)
			end
		end
	end
end
