# XML parser for EimXML
#
# Copyright (C) 2006, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.
#

require "eim_xml"
require "strscan"

module EimXML
	class ParseError < StandardError
	end

	class Parser
		attr_reader :scanner
		module RE
			EMPTY_ELEMENT = /<([^>]*?)\/>/
			START_TAG = /<([^>]*?([^\/>]\s*))>/
			END_TAG = /<\/(\S+)\s*>/
			ATTRIBUTE = /\s+([^=\s]+)\s*=\s*('(.*?)'|"(.*?)")/m
			STRING = /[^<]+/
		end

		def initialize(src, *space_holders)
			@scanner = StringScanner.new(src)
			@space_holders = []
			@space_holder_res = []
			space_holders.each do |i|
				if i.is_a?(Regexp)
					@space_holder_res << i
				else
					@space_holders << i.to_sym
				end
			end
		end

		def parse(hold_space = false)
			@scanner.scan(/\s+/) unless hold_space
			if @scanner.scan(RE::EMPTY_ELEMENT)
				parse_empty_element(hold_space)
			elsif @scanner.scan(RE::START_TAG)
				parse_start_tag(hold_space)
			elsif @scanner.scan(RE::STRING)
				parse_string(hold_space)
			else
				nil
			end
		end

		def parse_tag
			s = StringScanner.new(@scanner[1])
			e = Element.new(s.scan(/\S+/))
			e[s[1]] = s[3] ? s[3] : s[4] while s.scan(RE::ATTRIBUTE)
			e
		end
		protected :parse_tag

		def space_holder?(ename)
			return true if @space_holders.include?(ename)
			s = ename.to_s
			@space_holder_res.each do |re|
				return true if re=~s
			end
			false
		end

		def parse_empty_element(hold_space)
			e = parse_tag
			hold_space = space_holder?(e.name) unless hold_space
			e.hold_space if hold_space
			e
		end
		protected :parse_empty_element

		def parse_start_tag(hold_space)
			e = parse_tag
			hold_space = space_holder?(e.name) unless hold_space

			e.hold_space if hold_space
			@scanner.scan(/\s*/) unless hold_space
			until @scanner.scan(RE::END_TAG)
				c = parse(hold_space)
				raise ParseError.new("Syntax error.") unless c
				e << c
				@scanner.scan(/\s*/) unless hold_space
			end
			raise ParseError.new("End tag mismatched.") unless @scanner[1].to_sym==e.name
			e
		end
		protected :parse_start_tag

		def parse_string(hold_space)
			s = @scanner[0]
			s = s.strip unless hold_space
			s = s.gsub(/&(amp|quot|apos|lt|gt);/) do
				case $1
				when "amp"
					"&"
				when "quot"
					'"'
				when "apos"
					"'"
				when "lt"
					"<"
				when "gt"
					">"
				else
					raise "must not happen"
				end
			end
			PCString.new(s)
		end
		protected :parse_string
	end
end
