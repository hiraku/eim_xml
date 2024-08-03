module EimXML
  class Formatter
    class ElementWrapper
      def each(option, &)
        contents(**option).each(&)
      end
    end
  end
end
