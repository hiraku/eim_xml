# Easy IMplementation of XML
#
# Copyright (C) 2006, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.
#

module EimXML
	XML_DECLARATION = %[<?xml version="1.0"?>]

	class BaseDSL
		def initialize
			@container = nil
			yield(self) if block_given?
		end

		def add(v)
			@container.add(v)
		end
		alias << add

		def self.register(*args)
			args.each do |klass, name|
				name ||= klass.name.downcase[/(?:.*\:\:)?(.*)$/, 1]
				l = __LINE__+1
				src = "def #{name}(*arg, &proc)\n" <<
					"e = #{klass}.new(*arg)\n" <<
					"@container << e if @container\n" <<
					"if proc\n" <<
					"oc = @container\n" <<
					"@container = e\n" <<
					"begin\n" <<
					"instance_eval(&proc)\n" <<
					"ensure\n" <<
					"@container = oc\n" <<
					"end\n" <<
					"end\n" <<
					"e\n" <<
					"end"
				eval(src, binding, __FILE__, l)

				l = __LINE__+1
				src = "def self.#{name}(*arg, &proc)\n" <<
					"new.#{name}(*arg, &proc)\n" <<
					"end"
				eval(src, binding, __FILE__, l)
			end
		end
	end

	class DSL < BaseDSL
	end

	class OpenDSL
		def self.register_base(dsl, binding, *args)
			args.each do |klass, name|
				name ||= klass.name.downcase[/(?:.*\:\:)?(.*)$/, 1]
				src = "def #{name}(*arg)\n" <<
					"e=#{klass}.new(*arg)\n" <<
					"oc=@container\n" <<
					"oc << e if oc.is_a?(Element)\n" <<
					"@container = e\n" <<
					"begin\n" <<
					"yield(self) if block_given?\n" <<
					"e\n" <<
					"ensure\n" <<
					"@container = oc\n" <<
					"end\n" <<
					"end\n"
				eval(src, binding, __FILE__, __LINE__-12)

				src = "def self.#{name}(*arg, &proc)\n" <<
					"self.new.#{name}(*arg, &proc)\n" <<
					"end"
				eval(src, binding, __FILE__, __LINE__-3)
			end
		end

		def self.register(*args)
			register_base(self, binding, *args)
		end

		attr_reader :container
		def initialize
			@container = nil
			yield(self) if block_given?
		end

		def add(v)
			@container.add(v)
		end
		alias :<< :add
	end

	class PCString
		attr_reader :encoded_string
		alias to_s encoded_string

		def self.encode(s)
			s.gsub(/[&\"\'<>]/) do |m|
				case m
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

		def to_xml(dst=String.new)
			dst << encoded_string
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
			when Array
				v.each{|i| self.add(i)}
			else
				@contents << v
			end
			self
		end
		alias << add

		def to_xml(dst=String.new, nest_level=0)
			nest_level = nil if @hold_space
			hold_space = @hold_space || (not nest_level)
			nest = nest_level ? NEST*(nest_level) : ""
			lf = hold_space ? "" : "\n"

			attributes = ""
			@attributes.each do |k, v|
				v = k.to_s unless v
				attributes << " #{k}='#{PCString===v ? v : PCString.encode(v.to_s)}'"
			end

			case @contents.size
			when 0
				dst << "<#{@name}#{attributes} />"
			when 1
				dst << "<#{@name}#{attributes}>"
				content_to_xml(dst, @contents[0], nest_level, false)
				dst << "</#{@name}>"
			else
				dst << "<#{@name}#{attributes}>" << lf
				nest4contents = nest_level ? NEST*(nest_level+1) : ""
				@contents.each do |c|
					dst << nest4contents
					content_to_xml(dst, c, nest_level, true)
					dst << lf
				end
				dst << nest
				dst << "</#{@name}>"
			end
		end

		def to_s
			to_xml
		end
		alias :inspect :to_s

		def content_to_xml(dst, c, nest_level, increment_nest_level)
			case c
			when Element
				nest_level+=1 if nest_level and increment_nest_level
				c.to_xml(dst, nest_level)
			when PCString
				c.to_xml(dst)
			else
				dst << PCString.encode(c.to_s)
			end
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
		alias has_element? has?

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
	OpenDSL.register Element
end
