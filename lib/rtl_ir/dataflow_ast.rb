module RTL

  class PyVerilogNode
    attr_accessor :pos
    attr_accessor :attributes
    def initialize attributes={}
      @attributes=attributes
    end

    def method_missing(m, *args, &block)
      @attributes[m.to_s]
    end
  end

  class DesignUnit
    attr_accessor :directive,:instance,:terms,:binds
  end

  class Instance < PyVerilogNode
  end

  class Term < PyVerilogNode
  end

  class IntConst < PyVerilogNode
    def value
      @attributes.first
    end

    def int_value
      str=value.to_s
      str.match(/\d*\'?[bhd]?(\w*)/)[1].to_i
    end
  end

  class Terminal < PyVerilogNode
    def name
      @attributes.first
    end
  end

  class Branch < PyVerilogNode
  end

  class Operator < PyVerilogNode
    def type
      @attributes.first
    end

    def next
      @attributes[1]["Next"]
    end
  end

  class Partselect < PyVerilogNode
  end

  class Bind < PyVerilogNode
  end

  class Binary
    attr_accessor :lhs,:rhs
    def initialize l,r
      @lhs,@rhs=l,r
    end
  end

  class Pointed < Binary
    def to_s
      "#{@lhs.to_s}.#{@rhs.to_s}"
    end
  end

end
