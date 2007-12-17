require "eim_xml"

module EimXML::Assertions
	def assert_has(expect, element, message="")
		message << "\n" unless message.size==0
		message << "<#{element}> doesn't have\n<#{expect.inspect}>"
		assert_block(message) do
			element.has?(expect)
		end
	rescue Test::Unit::AssertionFailedError=>e
		bt = e.backtrace.find_all do |b|
			b !~ /#{Regexp.escape(__FILE__)}/
		end
		raise Test::Unit::AssertionFailedError, e.message, bt
	end
end
