# Easy IMplementation of XML
#
# Copyright (C) 2006, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.
#

module EimXML
	XML_DECLARATION = %[<?xml version="1.0"?>]

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

		def to_xml(dst=String.new, *)
			dst << encoded_string
		end
	end

	class Comment
		def initialize(text)
			raise ArgumentError, "Can not include '--'" if text =~ /--/
			@text = text
		end

		def to_xml(dst=String.new, nest_level=nil)
			dst << "<!-- #{@text} -->"
		end
	end

	class Element
		attr_reader :name, :attributes, :contents

		NEST = " "

		def initialize(name, attributes=nil)
			@name = name.to_sym
			@attributes = Hash.new
			@contents = Array.new
			@preserve_space = false

			@attributes.update(attributes) if attributes

			yield(self) if block_given?
		end

		def name=(new_name)
			@name = new_name.to_sym
		end
		protected :name=

		def preserve_space
			@preserve_space = true
			self
		end

		def preserve_space?
			@preserve_space
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

		def need_format?(o)
			o==nil || o.respond_to?(:to_xml) && !(o.is_a?(PCString))
		end

		def to_xml(dst=String.new, nest_level=0)
			nest_level = nil if @preserve_space
			preserve_space = @preserve_space || (not nest_level)
			nest = nest_level ? NEST*(nest_level) : ""
			lf = preserve_space ? "" : "\n"

			attributes = ""
			@attributes.each do |k, v|
				next unless v
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
				dst << "<#{@name}#{attributes}>"
				nest4contents = nest_level ? NEST*(nest_level+1) : ""
				prev = nil
				@contents.each do |c|
					dst << lf << nest4contents if need_format?(prev) && need_format?(c)
					content_to_xml(dst, c, nest_level, true)
					prev = c
				end
				dst << lf << nest if need_format?(prev)
				dst << "</#{@name}>"
			end
		end

		def to_s
			to_xml
		end
		alias :inspect :to_s

		def content_to_xml(dst, c, nest_level, increment_nest_level)
			if c.respond_to?(:to_xml)
				nest_level+=1 if nest_level and increment_nest_level
				c.to_xml(dst, nest_level)
			else
				dst << PCString.encode(c.to_s)
			end
		end
		private :content_to_xml

		def ==(xml)
			return false unless xml.is_a?(Element)
			(@name==xml.name && @attributes==xml.attributes && @contents==xml.contents && @preserve_space==xml.preserve_space?)
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

		def match(obj, attr=nil)
			return match(Element.new(obj, attr)) if attr
			return obj=~@name.to_s if obj.is_a?(Regexp)
			return @name==obj if obj.is_a?(Symbol)
			return is_a?(obj) if obj.is_a?(Module)

			raise ArgumentError unless obj.is_a?(Element)

			return false unless @name==obj.name

			obj.attributes.all? do |k, v|
				v===@attributes[k]
			end and obj.contents.all? do |i|
				case i
				when Element
					has_element?(i)
				when String
					@contents.include?(i)
				when Regexp
					@contents.any?{|c| c.is_a?(String) and i=~c}
				end					
			end
		end
		alias :=~ :match

		def has?(obj, attr=nil)
			return has?(Element.new(obj, attr)) if attr

			@contents.any? do |i|
				if i.is_a?(Element)
					i.match(obj) || i.has?(obj)
				else
					obj.is_a?(Module) && i.is_a?(obj)
				end
			end
		end
		alias has_element? has?
		alias include? has?

		def find(obj, dst=Element.new(:found))
			return find(Element.new(obj, dst)) if dst.is_a?(Hash)

			dst << self if match(obj)
			@contents.each do |i|
				case
				when i.is_a?(Element)
					i.find(obj, dst)
				when obj.is_a?(Module) && i.is_a?(obj)
					dst << i
				end
			end
			dst
		end
	end
end
