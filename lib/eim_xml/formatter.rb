require "eim_xml"

module EimXML
	class Formatter
		attr_reader :out

		def self.write(element, opt={})
			opt = {:out=>""}.merge(opt)
			new(opt).write(element)
			opt[:out]
		end

		def initialize(opt)
			@out = opt[:out]
			@preservers = opt[:preservers]
			@preserve_space = false
			@indent_string = "  "
			@indent_depth = 0
			@option = opt.dup.tap{|h| [:out, :preservers].each{|k| h.delete(k)}}
		end

		def write(src)
			case src
			when ElementWrapper
				write_wrapper(src)
			when Comment
				write_comment(src)
			when Element
				write_element(src)
			when PCString
				write_pcstring(src)
			else
				write_string(src.to_s)
			end
		end

		def indent(&proc)
			@indent_depth += 1
			proc.call
		ensure
			@indent_depth -= 1
		end

		def preserve_space_element?(elm)
			@preservers && @preservers.any? do |e|
				case e
				when Symbol
					e==elm.name
				when Class
					e===elm
				end
			end
		end

		def write_indent
			out << @indent_string*@indent_depth unless @preserve_space
		end

		def write_newline
			out << "\n" unless @preserve_space
		end

		def write_comment(c)
			write_indent
			c.write_to(out)
			write_newline
		end

		def write_contents_of(elm)
			flag = @preserve_space
			@preserve_space = true if preserve_space_element?(elm)
			write_newline
			indent do
				elm.contents.each do |c|
					write(c)
				end
			end
			write_indent
		ensure
			@preserve_space = flag
		end

		def write_element(elm)
			write_indent
			out << "<"
			elm.name_and_attributes(out)
			case elm.contents.size
			when 0
				out << " />"
				write_newline
			else
				out << ">"
				write_contents_of(elm)
				out << "</#{elm.name}>"
				write_newline
			end
		end

		def write_pcstring(pcs)
			pcs.encoded_string.each_line do |l|
				write_indent
				out << l
			end
			write_newline
		end

		def write_string(str)
			PCString.encode(str).each_line do |l|
				write_indent
				out << l
			end
			write_newline
		end

		def write_wrapper(wrapper)
			wrapper.each(@option) do |i|
				write(i)
			end
		end
	end
end

require "eim_xml/formatter/element_wrapper"
