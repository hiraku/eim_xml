require "eim_xml"
require "eim_xml/formatter"

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

		def initialize(attributes={})
			super(:html, attributes)
		end

		def write_to(out="")
			out << @prefix << "\n" if @prefix
			super
		end
	end

	class Simple_ < Base_
		def initialize(attributes={})
			super(self.class.name[/.*::(.*)/, 1].downcase.to_sym, attributes)
		end
	end

	class PreserveSpace_ < Base_
		def initialize(name={}, attributes={})
			if name.is_a?(Hash)
				super(self.class.name[/.*::(.*)/, 1].downcase.to_sym, name)
			else
				super(name, attributes)
			end
		end
	end

	class HEAD < Simple_; end
	class META < Simple_; end
	class LINK < Simple_; end
	class STYLE < PreserveSpace_; end
	class SCRIPT < PreserveSpace_; end
	class TITLE < Simple_; end
	class BODY < Simple_; end
	class PRE < PreserveSpace_; end
	class FORM < Simple_
		def initialize(attributes={})
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
	class H1 < PreserveSpace_; end
	class H2 < PreserveSpace_; end
	class H3 < PreserveSpace_; end
	class H4 < PreserveSpace_; end
	class H5 < PreserveSpace_; end
	class H6 < PreserveSpace_; end
	class P < PreserveSpace_; end
	class A < PreserveSpace_; end
	class EM < PreserveSpace_; end
	class STRONG < PreserveSpace_; end
	class DIV < Simple_; end
	class SPAN < PreserveSpace_; end
	class UL < Simple_; end
	class OL < Simple_; end
	class LI < PreserveSpace_; end
	class DL < Simple_; end
	class DT < PreserveSpace_; end
	class DD < PreserveSpace_; end
	class TABLE < Simple_; end
	class CAPTION < PreserveSpace_; end
	class TR < Simple_; end
	class TH < PreserveSpace_; end
	class TD < PreserveSpace_; end
	class BR < Simple_; end
	class HR < Simple_; end

	module Hn
		def self.new(level, attr={}, &proc)
			raise ArgumentError unless 1<=level && level<=6
			klass = EimXML::XHTML.const_get("H#{level}")
			klass.new(attr, &proc)
		end
	end

	class TEXTAREA < PreserveSpace_; end

	class INPUT < Base_
		def initialize(opt={})
			super(:input, opt)
		end
	end

	class BUTTON < PreserveSpace_
		def initialize(opt={})
			super(:button, opt)
		end
	end

	class SUBMIT < BUTTON
		def initialize(opt={})
			super(opt.merge(:type=>:submit))
		end
	end

	class HIDDEN < INPUT
		def initialize(opt={})
			super(opt.merge(:type=>:hidden))
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

	PRESERVE_SPACES = [PreserveSpace_]
	class Formatter < EimXML::Formatter
		def self.write(element, opt={})
			EimXML::Formatter.write(element, opt.merge(:preservers=>PRESERVE_SPACES))
		end
	end
end
