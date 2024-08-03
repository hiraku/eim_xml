# Test for eim_xml/assertions.rb
#
# Copyright (C) 2006, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.

$:.unshift "#{File.dirname(File.dirname(File.expand_path(__FILE__)))}/lib"
require 'test/unit'
require 'eim_xml/assertions'

class EimXMLAssertionsTest < Test::Unit::TestCase
  include EimXML
  include EimXML::Assertions

  def test_assert_has
    e = Element.new(:tag) do |tag|
      tag << Element.new(:sub)
    end

    assert_nothing_raised do
      assert_has(:sub, e)
    end

    a = assert_raises(Test::Unit::AssertionFailedError) do
      assert_has(:no, e)
    end
    assert(!a.backtrace.any? { |i|
      i =~ /eim_xml\/assertions\.rb/
    })
  end
end
