require "eim_xml"

module EimXML::XHTML
	module DocType
		XHTML_MATHML = %[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN" "http://www.w3.org/TR/MathML2/dtd/xhtml-math11-f.dtd">]
	end

	class Base_ < EimXML::Element
	end

	class HTML < Base_
		attr_accessor :prefix
		module NameSpace
			XHTML = "http://www.w3.org/1999/xhtml"
		end

		def initialize(attributes=nil)
			super(:html, attributes)
		end

		def write_to(out="")
			out << @prefix << "\n" if @prefix
			super
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
	class FORM < Simple_
		def initialize(attributes=nil)
			if attributes
				if s = attributes.delete(:session)
					name = attributes.delete(:session_name) || "token"
					require "digest/sha1"
					token = s[name] ||= Digest::SHA1.hexdigest("#{$$}#{Time.now}#{rand}")
				end
			end
			super
			add(HIDDEN.new(:name=>name, :value=>token)) if token
		end
	end
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
	class SPAN < Simple_; end
	class UL < Simple_; end
	class OL < Simple_; end
	class LI < Simple_; end
	class DL < Simple_; end
	class DT < Simple_; end
	class DD < Simple_; end
	class TABLE < Simple_; end
	class CAPTION < Simple_; end
	class TR < Simple_; end
	class TH < Simple_; end
	class TD < Simple_; end
	class BR < Simple_; end
	class HR < Simple_; end

	module Hn
		def self.new(level, attr=nil, &proc)
			raise ArgumentError unless 1<=level && level<=6
			klass = EimXML::XHTML.const_get("H#{level}")
			klass.new(attr, &proc)
		end
	end

	class TEXTAREA < Base_
		def initialize(opt={})
			super(:textarea, opt)
		end
	end

	class INPUT < Base_
		def initialize(opt={})
			super(:input, opt)
		end
	end

	class HIDDEN < INPUT
		def initialize(opt={})
			super(opt.merge(:type=>:hidden))
		end
	end

	class SUBMIT < INPUT
		def initialize(opt={})
			super(opt.merge(:type=>:submit))
		end
	end

	class TEXT < INPUT
		def initialize(opt={})
			super(opt.merge(:type=>:text))
		end
	end

	class PASSWORD < INPUT
		def initialize(opt={})
			super(opt.merge(:type=>:password))
		end
	end
end
