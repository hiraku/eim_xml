class EimXML::Formatter
	class ElementWrapper
		def each(option, &proc)
			contents(option).each(&proc)
		end
	end
end
