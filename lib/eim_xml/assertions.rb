require 'eim_xml'

module EimXML
  module Assertions
    def assert_has(expect, element, message = '')
      message << "\n" unless message.empty?
      message << "<#{element}> doesn't have\n<#{expect.inspect}>"
      assert_block(message) do
        element.has?(expect)
      end
    rescue Test::Unit::AssertionFailedError => e
      bt = e.backtrace.grep_v(/#{Regexp.escape(__FILE__)}/)
      raise Test::Unit::AssertionFailedError, e.message, bt
    end
  end
end
