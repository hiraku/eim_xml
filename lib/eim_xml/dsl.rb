# Easy IMplementation of XML
#
# Copyright (C) 2006,2008, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.
#

require 'eim_xml'

module EimXML
  class BaseDSL
    def add(content)
      @_container << content
    end
    alias << add

    def import_variables(src)
      src.instance_variables.each do |v|
        instance_variable_set(v, src.instance_variable_get(v)) unless v =~ /\A@_[^_]/
      end
      self
    end

    def _build(klass, *arg, &proc)
      e = klass.new(*arg)
      @_container << e if @_container
      if proc
        oc = @_container
        @_container = e
        begin
          instance_eval(&proc)
        ensure
          @_container = oc
        end
      end
      e
    end
    private :_build

    def _push(container)
      oc = @_container
      @_container = container
      begin
        yield if block_given?
        container
      ensure
        @_container = oc
      end
    end
    private :_push

    def self.register(*args)
      args.each do |klass, name|
        name ||= klass.name.downcase[/(?:.*::)?(.*)$/, 1]

        # rubocop:disable Security/Eval, Layout/LineLength
        eval("def #{name}(*a, &p);_build(#{klass}, *a, &p);end", binding, __FILE__, __LINE__) # def element(*a, &p);_build(Element, *a, &p);end
        eval("def self.#{name}(*a, &p);new.#{name}(*a, &p);end", binding, __FILE__, __LINE__) # def self.element(*a, &p);new.element(*a, &p);end
        # rubocop:enable Security/Eval, Layout/LineLength
      end
    end
  end

  class DSL < BaseDSL
  end

  class OpenDSL
    def _build(klass, *arg, &proc)
      e = klass.new(*arg)
      oc = @_container
      oc << e if oc.is_a?(Element)
      @_container = e
      begin
        proc&.call(self)
        e
      ensure
        @_container = oc
      end
    end
    private :_build

    def self.register_base(_dsl, binding, *args)
      args.each do |klass, name|
        name ||= klass.name.downcase[/(?:.*::)?(.*)$/, 1]

        # rubocop:disable Security/Eval, Layout/LineLength
        eval("def #{name}(*a, &p);_build(#{klass}, *a, &p);end", binding, __FILE__, __LINE__) # def element(*a, &p);_build(Element, *a, &p);end
        eval("def self.#{name}(*a, &p);self.new.#{name}(*a, &p);end", binding, __FILE__, __LINE__) # def self.element(*a, &p);self.new.element(*a, &p);end
        # rubocop:enable Security/Eval, Layout/LineLength
      end
    end

    def self.register(*)
      register_base(self, binding, *)
    end

    def initialize
      @_container = nil
      yield(self) if block_given?
    end

    def add(content)
      @_container.add(content)
    end
    alias << add

    def container
      @_container
    end
  end

  DSL.register Element, Comment
  OpenDSL.register Element, Comment
end
