module RTL

  class FSM
    attr_accessor :infos,:transitions
    def initialize infos,transitions
      @infos=infos
      @transitions=transitions
    end
  end

  class State
    attr_accessor :name
    def initialize name
      @name=name
    end
  end

  class Transition
    attr_accessor :from,:to,:cond
    def initialize from_,to_,cond
      @from,@to,@cond=from_,to_,cond
    end
  end

  class Binary
    attr_accessor :lhs,:rhs
    def initialize l,r
      @lhs,@rhs=l,r
    end
  end

  class BinaryOp < Binary
    attr_accessor :op
    def initialize l,op,r
      super(l,r)
      @op=op
    end
  end

  class Ident
    attr_reader :str
    def initialize str
      @str=str
    end
  end

  class Indexed < Binary
  end

  class Unary
    attr_accessor :expr
    def initialize e
      @expr=e
    end
  end

  class Not < Unary
  end

  class Parenth < Unary
  end

  class IntLit
    attr_accessor :value
    def initialize val_s
      @value=val_s
    end
  end
end
