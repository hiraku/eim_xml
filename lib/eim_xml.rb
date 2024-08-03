# Easy IMplementation of XML
#
# Copyright (C) 2006, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.
#

module EimXML
  XML_DECLARATION = %[<?xml version="1.0"?>]

  class PCString
    attr_reader :encoded_string, :src
    alias to_s encoded_string

    def self.encode(src)
      src.to_s.gsub(/[&\"\'<>]/) do |m|
        case m
        when '&'
          '&amp;'
        when '"'
          '&quot;'
        when "'"
          '&apos;'
        when '<'
          '&lt;'
        when '>'
          '&gt;'
        end
      end
    end

    def self.[](obj)
      obj.is_a?(PCString) ? obj : PCString.new(obj)
    end

    def initialize(src, encoded = false)
      @src = src
      @encoded_string = encoded ? src : PCString.encode(src)
    end

    def ==(other)
      other.is_a?(PCString) ? @encoded_string == other.encoded_string : self == PCString.new(other)
    end

    def write_to(out = '')
      out << encoded_string
    end
  end

  class Comment
    def initialize(text)
      raise ArgumentError, "Can not include '--'" if text =~ /--/

      @text = text
    end

    def write_to(out = '')
      out << "<!-- #{@text} -->"
    end
  end

  class Element
    attr_reader :name, :attributes, :contents

    NEST = ' '

    def initialize(name, attributes = {})
      @name = name.to_sym
      @attributes = Hash.new
      @contents = Array.new

      attributes.each do |k, v|
        @attributes[k.to_sym] = v
      end

      yield(self) if block_given?
    end

    def name=(new_name)
      @name = new_name.to_sym
    end
    protected :name=

    def add(content)
      case content
      when nil
        # nothing to do
      when Array
        content.each { |i| self.add(i) }
      else
        @contents << content
      end
      self
    end
    alias << add

    def name_and_attributes(out = '')
      out << "#{@name}"
      @attributes.each do |k, v|
        next unless v

        out << " #{k}='#{PCString === v ? v : PCString.encode(v.to_s)}'"
      end
    end

    def write_to(out = '')
      out << '<'
      name_and_attributes(out)

      if @contents.empty?
        out << ' />'
      else
        out << '>'
        @contents.each do |c|
          case c
          when Element
            c.write_to(out)
          when PCString
            out << c.to_s
          else
            out << PCString.encode(c.to_s)
          end
        end
        out << "</#{@name}>"
      end
      out
    end
    alias :to_s :write_to
    alias :inspect :to_s

    def ==(other)
      return false unless other.is_a?(Element)

      @name == other.name && @attributes == other.attributes && @contents == other.contents
    end

    def add_attribute(key, value)
      @attributes[key.to_sym] = value
    end
    alias []= add_attribute

    def [](key)
      if key.is_a?(Integer)
        @contents[key]
      else
        @attributes[key.to_sym]
      end
    end

    def del_attribute(key)
      @attributes.delete(key.to_sym)
    end

    def pcstring_contents
      @contents.select { |c| c.is_a?(String) || c.is_a?(PCString) }.map { |c| c.is_a?(String) ? PCString.new(c) : c }
    end

    def match(obj, attr = nil)
      return match(Element.new(obj, attr)) if attr
      return obj =~ @name.to_s if obj.is_a?(Regexp)
      return @name == obj if obj.is_a?(Symbol)
      return is_a?(obj) if obj.is_a?(Module)

      raise ArgumentError unless obj.is_a?(Element)

      return false unless @name == obj.name

      obj.attributes.all? do |k, v|
        (v.nil? && !@attributes.include?(k)) ||
          (@attributes.include?(k) && (v.is_a?(Regexp) ? v =~ @attributes[k] : PCString[v] == PCString[@attributes[k]]))
      end and obj.contents.all? do |i|
        case i
        when Element
          has_element?(i)
        when String
          pcstring_contents.include?(PCString.new(i))
        when PCString
          pcstring_contents.include?(i)
        when Regexp
          @contents.any? { |c| c.is_a?(String) and i =~ c }
        end
      end
    end
    alias :=~ :match

    def has?(obj, attr = nil)
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

    def find(obj, dst = Element.new(:found))
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
