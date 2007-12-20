# Easy IMplementation of XML
#
# Copyright (C) 2006, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.
#

module EimXML
	XML_DECLARATION = %[<?xml version="1.0"?>]

	module DSL
		def self.register_base(mod, binding, *args)
			args.each do |klass, name|
				name ||= klass.name.downcase[/(?:.*\:\:)?(.*)$/, 1]
				src = "def self.#{name}(*arg, &proc)\n" <<
					"r = #{klass.name}.new(*arg)\n" <<
					"r.instance_eval(&proc) if proc\n" <<
					"r\n" <<
					"end\n"
				eval(src, binding, __FILE__, __LINE__-5)

				src = "def #{name}(*arg, &proc)\n" <<
					"e=#{mod}.#{name}(*arg, &proc)\n" <<
					"add(e) if self.is_a?(EimXML::Element)\n" <<
					"e\n" <<
					"end\n"
				eval(src, binding, __FILE__, __LINE__-4)
			end
		end

		def self.register(*args)
			register_base(self, binding, *args)
		end
	end

	class PCString
		attr_reader :encoded_string
		alias to_s encoded_string

		def self.encode(s)
			s.gsub(/&\#?\w+;|[&\"\'<>]/) do |m|
				case m
				when /&\#?\w+;/
					m
				when "&"
					"&amp;"
				when '"'
					"&quot;"
				when "'"
					"&apos;"
				when "<"
					"&lt;"
				when ">"
					"&gt;"
				end
			end
		end

		def initialize(s, encoded=false)
			@encoded_string = encoded ? s : PCString.encode(s)
		end

		def ==(other)
			other.is_a?(PCString) ? @encoded_string==other.encoded_string : false
		end
	end

	class SymbolKeyHash < Hash
		def initialize(src=nil)
			case src
			when self.class
				super(src)
			when Hash
				src.each_key do |k|
					store(k, src[k])
				end
			end
		end

		def update(src)
			src = self.class.new(src) unless src.is_a?(self.class)
			super(src)
		end
		alias :merge! :update

		def merge(src)
			super(self.class.new(src))
		end

		def store(k, v)
			super(k.to_sym, v)
		end

		alias :[]= :store
	end

	class Element
		include DSL
		attr_reader :name, :attributes, :contents

		NEST = " "

		def initialize(name, attributes=nil)
			@name = name.to_sym
			@attributes = SymbolKeyHash.new
			@contents = Array.new
			@hold_space = false

			@attributes.update(attributes) if attributes

			yield(self) if block_given?
		end

		def name=(new_name)
			@name = new_name.to_sym
		end
		protected :name=

		def hold_space
			@hold_space = true
			self
		end

		def unhold_space
			@hold_space = false
			self
		end

		def hold_space?
			@hold_space
		end

		def add(v)
			case v
			when nil
			when Element, PCString
				@contents << v
			when Array
				v.each{|i| self.add(i)}
			else
				@contents << v.to_s
			end
			self
		end
		alias << add

		def to_xml(dst=String.new, nest_level=0, is_head=true)
			nest = NEST*nest_level
			head = is_head ? nest : ""
			lf = @hold_space ? "" : "\n"

			attributes = ""
			@attributes.each do |k, v|
				v = k.to_s unless v
				attributes << " #{k}='#{PCString===v ? v : PCString.encode(v.to_s)}'"
			end

			case @contents.size
			when 0
				dst << "#{head}<#{@name}#{attributes} />"
			when 1
				dst << "#{head}<#{@name}#{attributes}>"
				content_to_xml(dst, @contents[0], nest_level, false)
				dst << "</#{@name}>"
			else
				dst << "#{head}<#{@name}#{attributes}>#{lf}"
				@contents.each {|i| content_to_xml(dst, i, nest_level+1, !@hold_space) << lf}
				dst << "#{@hold_space ? "" : nest}</#{@name}>"
			end
		end
		def to_s(*args)
			args.unshift("")
			to_xml(*args)
		end
		alias :inspect :to_s

		def content_to_xml(dst, c, nest_level, is_head)
			return c.to_xml(dst, nest_level, is_head) if c.is_a?(Element)
			dst << (is_head ? NEST*nest_level : "") + (c.is_a?(PCString) ? c.to_s : PCString.encode(c))
		end
		private :content_to_xml

		def ==(xml)
			return false unless xml.is_a?(Element)
			(@name==xml.name && @attributes==xml.attributes && @contents==xml.contents && @hold_space==xml.hold_space?)
		end

		def add_attribute(key, value)
			@attributes[key.to_sym] = value
		end
		alias []= add_attribute

		def [](key)
			if key.is_a?(Fixnum)
				@contents[key]
			else
				@attributes[key.to_sym]
			end
		end

		def del_attribute(key)
			@attributes.delete(key.to_sym)
		end

		def match?(name, attrs=nil)
			case name
			when Module
				return is_a?(name)
			when Element
				return match?(name.name, name.attributes)
			when Array
				return match?(name[0], name[1])
			end

			if name.is_a?(Regexp)
				return false unless name=~@name.to_s
			else
				return false unless @name==name
			end

			(attrs||[]).all? do |k, v|
				if k.is_a?(Regexp)
					@attributes.any? do |sk, sv|
						next false unless k===sk.to_s
						v===sv
					end
				else
					ak = @attributes[k]
					if (ak.is_a?(String) or ak.is_a?(Symbol)) and (v.is_a?(String) or v.is_a?(Symbol))
						ak.to_s == v.to_s
					else
						v===@attributes[k]
					end
				end
			end
		end
		alias :=~ :match?

		def has?(name, attrs=nil, find_deep=true)
			return true if match?(name, attrs)
			@contents.any? do |i|
				if i.is_a?(Element)
					if find_deep
						i=~[name, attrs] || i.has?(name, attrs, find_deep)
					else
						i=~[name, attrs]
					end
				else
					name.is_a?(Module) && i.is_a?(name)
				end
			end
		end

		def find(name, attrs=nil)
			r = []
			r << self if match?(name, attrs)
			@contents.each do |i|
				if i.is_a?(Element)
					r.concat(i.find(name, attrs))
				else
					r << i if name.is_a?(Module) && i.is_a?(name)
				end
			end
			r
		end
	end

	DSL.register Element
end
