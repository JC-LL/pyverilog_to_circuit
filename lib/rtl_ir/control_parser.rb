require_relative './generic_parser'
require_relative 'control_lexer'
require_relative 'control_ast'

module RTL

  class ControlParser < GenericParser
    attr_accessor :tokens

    def parse filename
      begin
        str=IO.read(filename)
        @tokens=ControlLexer.new.tokenize(str)
        return parse_fsm()
      rescue Exception => e
         puts "PARSING ERROR : #{e}"
         puts "in source at line/col #{showNext.pos}"
         puts e.backtrace
         abort
      end
    end

    def parse_fsm
      expect :FSM
      infos=parse_fsm_attributes
      parse_comments
      transitions=parse_transitions
      return FSM.new(infos,transitions)
    end

    def parse_fsm_attributes
      ret={}
      conditions=[]
      while showNext.is_a? [:signal,:Condition]
        case showNext.kind
        when :signal
          ret.merge! parse_signal
        when :Condition
          conditions << parse_condition
        else
          raise "unknown FSM attribute '#{showNext}'"
        end
        acceptIt if showNext.is_a?(:comma)
      end
      ret[:conditions]=conditions
      ret
    end

    def parse_signal
      expect :signal
      expect :colon
      module_name=expect(:id).val
      expect :dot
      signal_name=expect(:id).val
      {:module_name=> module_name,:signal_name=> signal_name}
    end

    def parse_condition
      expect :Condition
      case showNext.kind
      when :list
        expect :list
        expect :length
        expect :colon
        value=expect(:int_lit).val.to_i
        expect :newline
        {:condition_list_length => value}
      when :colon
        acceptIt
        parse_unstructured_til_newline
        {:condition => :unstructured}
      else
        raise "unknown Condition, followed by '#{showNext}'"
      end
    end


    def parse_comments
      while showNext.is_a? :comment
        acceptIt
        expect :newline
      end
    end

    def parse_unstructured_til_newline
      while !showNext.is_a? :newline
        acceptIt
      end
      expect :newline
    end


    def parse_transitions
      trans=[]
      while showNext(2).is_a? :trans_start
        trans << parse_transition
      end
      trans
    end

    def parse_transition
      state_source=State.new(expect(:int_lit).val.to_i)
      expect :trans_start
      condition=parse_transition_condition
      expect :trans_end
      state_dest=State.new(expect(:int_lit).val.to_i)
      expect :newline
      Transition.new(state_source,state_dest,condition)
    end

    def parse_transition_condition
      parse_expression
    end

    #======================== Expressions ===================
    COMPARISON_OP=[:eq,:neq,:gt,:gte,:lt,:lte]
    def parse_expression
      t1=parse_additive
      while more? && showNext.is_a?(COMPARISON_OP)
        op=acceptIt.kind
        t2=parse_additive
        t1=BinaryOp.new(t1,op,t2)
      end
      return t1
    end

    ADDITIV_OP  =[:add,:sub, :or]
    def parse_additive
      t1=parse_multiplicative
      while more? && showNext.is_a?(ADDITIV_OP)
        op=acceptIt.kind #full token
        t2=parse_multiplicative
        t1=BinaryOp.new(t1,op,t2)
      end
      return t1
    end

    MULTITIV_OP=[:mul_sign,:div_sign,:mod_sign,:and,:shiftr,:shiftl]

    def parse_multiplicative
      t1=parseTerm
      while more? && showNext.is_a?(MULTITIV_OP)
        op=acceptIt.kind
        t2=parseTerm
        t1=BinaryOp.new(t1,op,t2)
      end
      return t1
    end

    def parseTerm
      case showNext.kind
      when :None
        ret=acceptIt
      when :verilog_int_lit
        ret=IntLit.new(acceptIt.val)
      when :not
        acceptIt
        ret=parse_expression
        ret=Not.new(ret)
      when :id
        ret=id=Ident.new(acceptIt.val)
        while showNext.is_a? :lbrack
          if idx=indexed?
            idx.lhs=ret
            ret=idx
          end
        end
      when :lparen
        ret=parseParenth
      when :add,:sub,:not
        ret=parseUnary
      else
        raise "Parser ERROR : parseTerm does not expect '#{showNext.val}' [#{showNext.kind}] at line #{showNext.pos.first}"
      end
      ret
    end

    def indexed?
      if showNext.is_a? :lbrack
        acceptIt
        rhs=parse_expression()
        ret=Indexed.new(nil,rhs)
        expect :rbrack
      else
        return false
      end
      return ret
    end

    def parseParenth
      expect :lparen
      expr=parse_expression
      expect :rparen
      Parenth.new(expr)
    end

  end #class parser
end
