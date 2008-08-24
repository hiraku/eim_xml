# Easy IMplementation of XML
#
# Copyright (C) 2006,2008, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.
#

require "eim_xml"

module EimXML
	class BaseDSL
		def initialize
			@_container = nil
			yield(self) if block_given?
		end

		def add(v)
			@_container.add(v)
		end
		alias << add

		def self.register(*args)
			args.each do |klass, name|
				name ||= klass.name.downcase[/(?:.*\:\:)?(.*)$/, 1]
				l = __LINE__+1
				src = "def #{name}(*arg, &proc)\n" <<
					"e = #{klass}.new(*arg)\n" <<
					"@_container << e if @_container\n" <<
					"if proc\n" <<
					"oc = @_container\n" <<
					"@_container = e\n" <<
					"begin\n" <<
					"instance_eval(&proc)\n" <<
					"ensure\n" <<
					"@_container = oc\n" <<
					"end\n" <<
					"end\n" <<
					"e\n" <<
					"end"
				eval(src, binding, __FILE__, l)

				l = __LINE__+1
				src = "def self.#{name}(*arg, &proc)\n" <<
					"new.#{name}(*arg, &proc)\n" <<
					"end"
				eval(src, binding, __FILE__, l)
			end
		end
	end

	class DSL < BaseDSL
	end

	class OpenDSL
		def self.register_base(dsl, binding, *args)
			args.each do |klass, name|
				name ||= klass.name.downcase[/(?:.*\:\:)?(.*)$/, 1]
				src = "def #{name}(*arg)\n" <<
					"e=#{klass}.new(*arg)\n" <<
					"oc=@_container\n" <<
					"oc << e if oc.is_a?(Element)\n" <<
					"@_container = e\n" <<
					"begin\n" <<
					"yield(self) if block_given?\n" <<
					"e\n" <<
					"ensure\n" <<
					"@_container = oc\n" <<
					"end\n" <<
					"end\n"
				eval(src, binding, __FILE__, __LINE__-12)

				src = "def self.#{name}(*arg, &proc)\n" <<
					"self.new.#{name}(*arg, &proc)\n" <<
					"end"
				eval(src, binding, __FILE__, __LINE__-3)
			end
		end

		def self.register(*args)
			register_base(self, binding, *args)
		end

		def initialize
			@_container = nil
			yield(self) if block_given?
		end

		def add(v)
			@_container.add(v)
		end
		alias :<< :add

		def container; @_container; end
	end

	DSL.register Element
	OpenDSL.register Element
end
