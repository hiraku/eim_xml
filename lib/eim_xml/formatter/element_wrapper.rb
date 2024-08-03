module EimXML
  class Formatter
    class ElementWrapper
      def each(option, &proc)
        contents(**option).each(&proc)
      end
    end
  end
end
