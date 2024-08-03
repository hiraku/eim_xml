require 'eim_xml'
require 'eim_xml/formatter'

module EimXML::XHTML
  module DocType
    XHTML_MATHML = %[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN" "http://www.w3.org/Math/DTD/mathml2/xhtml-math11-f.dtd">]
  end

  class Base < EimXML::Element
  end

  class HTML < Base
    attr_accessor :prefix

    module NameSpace
      XHTML = 'http://www.w3.org/1999/xhtml'
    end

    def initialize(attributes = {})
      super(:html, attributes)
    end

    def write_to(out = '')
      out << @prefix << "\n" if @prefix
      super
    end
  end

  class Simple < Base
    def initialize(attributes = {})
      super(self.class.name[/.*::(.*)/, 1].downcase.to_sym, attributes)
    end
  end

  class PreserveSpace < Base
    def initialize(name = {}, attributes = {})
      if name.is_a?(Hash)
        super(self.class.name[/.*::(.*)/, 1].downcase.to_sym, name)
      else
        super(name, attributes)
      end
    end
  end

  class HEAD < Simple; end
  class META < Simple; end
  class LINK < Simple; end
  class IMG < Simple; end
  class STYLE < PreserveSpace; end
  class SCRIPT < PreserveSpace; end
  class TITLE < Simple; end
  class BODY < Simple; end
  class PRE < PreserveSpace; end

  class FORM < Simple
    def initialize(attributes = {})
      if attributes
        if (s = attributes.delete(:session))
          name = attributes.delete(:session_name) || 'token'
          require 'digest/sha1'
          token = s[name] ||= Digest::SHA1.hexdigest("#{$$}#{Time.now}#{rand}")
        end
      end
      super
      add(HIDDEN.new(name: name, value: token)) if token
    end
  end

  class H1 < PreserveSpace; end
  class H2 < PreserveSpace; end
  class H3 < PreserveSpace; end
  class H4 < PreserveSpace; end
  class H5 < PreserveSpace; end
  class H6 < PreserveSpace; end
  class P < PreserveSpace; end
  class A < PreserveSpace; end
  class EM < PreserveSpace; end
  class STRONG < PreserveSpace; end
  class DIV < Simple; end
  class SPAN < PreserveSpace; end
  class UL < Simple; end
  class OL < Simple; end
  class LI < PreserveSpace; end
  class DL < Simple; end
  class DT < PreserveSpace; end
  class DD < PreserveSpace; end
  class TABLE < Simple; end
  class CAPTION < PreserveSpace; end
  class TR < Simple; end
  class TH < PreserveSpace; end
  class TD < PreserveSpace; end
  class BR < Simple; end
  class HR < Simple; end
  class SELECT < Simple; end
  class OPTION < Simple; end

  module Hn
    def self.new(level, attr = {}, &proc)
      raise ArgumentError unless 1 <= level && level <= 6

      klass = EimXML::XHTML.const_get("H#{level}")
      klass.new(attr, &proc)
    end
  end

  class TEXTAREA < PreserveSpace; end

  class INPUT < Base
    def initialize(opt = {})
      super(:input, opt)
    end
  end

  class BUTTON < PreserveSpace
    def initialize(opt = {})
      super(:button, opt)
    end
  end

  class SUBMIT < BUTTON
    def initialize(opt = {})
      super(opt.merge(type: :submit))
    end
  end

  class HIDDEN < INPUT
    def initialize(opt = {})
      super(opt.merge(type: :hidden))
    end
  end

  class TEXT < INPUT
    def initialize(opt = {})
      super(opt.merge(type: :text))
    end
  end

  class PASSWORD < INPUT
    def initialize(opt = {})
      super(opt.merge(type: :password))
    end
  end

  class FILE < INPUT
    def initialize(opt = {})
      super(opt.merge(type: :file))
    end
  end

  PRESERVE_SPACES = [PreserveSpace]
  class Formatter < EimXML::Formatter
    def self.write(element, opt = {})
      EimXML::Formatter.write(element, opt.merge(preservers: PRESERVE_SPACES))
    end
  end
end
