# XML parser for EimXML
#
# Copyright (C) 2006, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.
#

require 'eim_xml'
require 'strscan'

module EimXML
  class ParseError < StandardError
  end

  class Parser
    attr_reader :scanner

    module RE
      EMPTY_ELEMENT = %r{<([^>]*?)/>}
      START_TAG = %r{<([^>]*?([^/>]\s*))>}
      END_TAG = %r{</(\S+?)\s*>}
      ATTRIBUTE = /\s+([^=\s]+)\s*=\s*('(.*?)'|"(.*?)")/m
      STRING = /[^<]+/
    end

    PARSING_MAP = {
      'amp' => '&',
      'quot' => '"',
      'apos' => "'",
      'lt' => '<',
      'gt' => '>'
    }

    def initialize(src)
      @scanner = StringScanner.new(src)
      @scanner.scan(/\s*<\?.*?\?>\s*/)
    end

    def parse
      if @scanner.scan(RE::EMPTY_ELEMENT)
        parse_empty_element
      elsif @scanner.scan(RE::START_TAG)
        parse_start_tag
      elsif @scanner.scan(RE::STRING)
        parse_string
      end
    end

    def parse_tag
      s = StringScanner.new(@scanner[1])
      e = Element.new(s.scan(/\S+/))
      e[s[1]] = s[3] || s[4] while s.scan(RE::ATTRIBUTE)
      e
    end
    protected :parse_tag

    def parse_empty_element
      parse_tag
    end
    protected :parse_empty_element

    def parse_start_tag
      e = parse_tag

      until @scanner.scan(RE::END_TAG)
        c = parse
        raise ParseError, 'Syntax error.' unless c

        e << c
      end
      raise ParseError, 'End tag mismatched.' unless @scanner[1].to_sym == e.name

      e
    end
    protected :parse_start_tag

    def parse_string
      s = @scanner[0]
      s = s.gsub(/&(amp|quot|apos|lt|gt);/) do
        PARSING_MAP[Regexp.last_match(1)]
      end
      PCString.new(s)
    end
    protected :parse_string
  end
end
