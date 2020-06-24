require_relative 'circuit'

module RTL

    class Reg < Circuit
      def initialize name=nil
        super(name)
        add Port.new("D",:in)
        add Port.new("Q",:out)
      end
    end

    class UnaryGate < Circuit
      def initialize name=nil
        super(name)
        add Port.new("i",:in)
        add Port.new("f" ,:out)
      end
    end

    class NotGate < UnaryGate
    end

    class BinaryGate < Circuit
      def initialize name=nil
        super(name)
        add Port.new("i1",:in)
        add Port.new("i2",:in)
        add Port.new("f" ,:out)
      end
    end

    class AndGate < BinaryGate
    end

    class OrGate < BinaryGate
    end

    class XorGate < BinaryGate
    end

    class EqGate < BinaryGate
    end

    class NaryGate < Circuit
      attr_accessor :arity
      def initialize name=nil
        super(name)
        @arity=0
        add Port.new("f" ,:out)
      end

      def add port
        @arity+=1
        super(port)
      end
    end

    class OrNGate < NaryGate
    end

    class TimesGate < BinaryGate
    end

    class EqlGate < BinaryGate
    end

    class GreaterThanGate < BinaryGate
    end

    class LessThanGate < BinaryGate
    end

    class PlusGate < BinaryGate
    end

    class MinusGate < BinaryGate
    end

    class SllGate < BinaryGate
    end

end
