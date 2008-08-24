require "eim_xml/dsl"
require "eim_xml/xhtml"

module EimXML::XHTML
	class DSL < EimXML::BaseDSL
	end

	class OpenDSL < EimXML::OpenDSL
	end

	constants.each do |c|
		v = const_get(c)
		if v.is_a?(Class) && /_$/ !~ v.name
			DSL.register v
			OpenDSL.register v
		end
	end
end
