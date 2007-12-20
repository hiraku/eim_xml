require "eim_xml"

module EimXML::XHTML
	module DocType
		XHTML_MATHML = %[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN" "http://www.w3.org/TR/MathML2/dtd/xhtml-math11-f.dtd">]
	end

	module DSL
		def self.register(*args)
			EimXML::DSL.register_base(self, binding, *args)
		end

		def kp(*args)
			Kernel.p(*args)
		end
	end

	class Base_ < EimXML::Element
		include DSL
	end

	class HTML < Base_
		module NameSpace
			XHTML = "http://www.w3.org/1999/xhtml"
		end

		def initialize(attributes=nil)
			super(:html, attributes)
		end

		def to_xml(dst=String.new, write_declarations=true)
			if write_declarations
				dst << EimXML::XML_DECLARATION << "\n"
				dst << DocType::XHTML_MATHML << "\n"
			end
			super(dst)
		end
	end

	class Simple_ < Base_
		def initialize(attributes=nil)
			super(self.class.name[/.*::(.*)/, 1].downcase.to_sym, attributes)
		end
	end

	class HEAD < Simple_; end
	class META < Simple_; end
	class LINK < Simple_; end
	class STYLE < Simple_; end
	class SCRIPT < Simple_; end
	class TITLE < Simple_; end
	class BODY < Simple_; end
	class PRE < Simple_; end
	class FORM < Simple_; end
	class H1 < Simple_; end
	class H2 < Simple_; end
	class H3 < Simple_; end
	class H4 < Simple_; end
	class H5 < Simple_; end
	class H6 < Simple_; end
	class P < Simple_; end
	class A < Simple_; end
	class EM < Simple_; end
	class STRONG < Simple_; end
	class DIV < Simple_; end
	class UL < Simple_; end
	class OL < Simple_; end
	class LI < Simple_; end
	class TABLE < Simple_; end
	class CAPTION < Simple_; end
	class TR < Simple_; end
	class TH < Simple_; end
	class TD < Simple_; end

	module Hn
		def self.new(level, attr=nil, &proc)
			raise ArgumentError unless 1<=level && level<=6
			klass = EimXML::XHTML.const_get("H#{level}")
			klass.new(attr, &proc)
		end
	end

	class TEXTAREA < Base_
		def initialize(name, opt={})
			super(:textarea, {:name=>name}.merge(opt))
		end
	end

	class INPUT < Base_
		def initialize(type, name, value, opt={})
			attr = {:type=>type}
			attr[:name]=name if name
			attr[:value]=value if value
			super(:input, attr.merge(opt))
		end
	end

	class HIDDEN < INPUT
		def initialize(name, value, opt={})
			super(:hidden, name, value, opt)
		end
	end

	class SUBMIT < INPUT
		def initialize(opt={})
			opt = opt.dup
			super(:submit, opt.delete(:name), opt.delete(:value), opt)
		end
	end

	class TEXT < INPUT
		def initialize(name, value=nil, opt={})
			super(:text, name, value, opt)
		end
	end

	constants.each do |c|
		v = const_get(c)
		if v.is_a?(Class) && /_$/ !~ v.name
			DSL.register v
		end
	end
end
