require 'eim_xml'

module EimXML
  module Matchers
    class HaveContent
      def initialize(expected)
        @expected = expected
      end

      def matches?(target)
        @target = target
        @target.has?(@expected)
      end

      def failure_message
        "expected #{@target.inspect} must have #{@expected}, but not."
      end

      def negative_failure_message
        "expected #{@target.inspect} must not have #{@expected}, but has."
      end
    end

    def have(expected)
      HaveContent.new(expected)
    end
  end
end
