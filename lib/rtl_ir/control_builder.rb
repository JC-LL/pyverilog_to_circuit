require_relative './generic_parser'
require_relative 'control_lexer'
require_relative 'control_ast'
require_relative 'circuit'
require_relative 'rtl_circuit'
require_relative 'circuit_dot_printer'

module RTL

  class ControlBuilder
    attr_reader :fsm
    # returns a circuit
    def build fsm
      @symtable={}
      @fsm=fsm
      @circuit=Circuit.new fsm.infos[:module_name]
      # add state registers (one-hot only)
      build_register_states
      # build netlist
      build_netlist
      @circuit.view
      @circuit
    end

    def build_register_states
      @code_reg_h={}
      state_codes=fsm.transitions.collect{|trans| [trans.from,trans.to].map(&:name)}.flatten.uniq.sort
      state_codes.collect do |code|
        reg_id=one_hot_state_bit(code)
        @circuit.add reg=Reg.new(name="R#{reg_id}")
        reg.params[:state]=code
        @code_reg_h[code]=reg
        reg
      end
    end

    def one_hot_state_bit number
      i=0
      while true
        pos=1<<i
        return i if number==pos
        i+=1
      end
    end

    def build_netlist
      @fsm.transitions.each do |trans|
        s_from,s_to=trans.from, trans.to
        cond_port=build_cond_rec(trans.cond)
        #--- starting state
        reg=@code_reg_h[s_from.name]
        q=reg.port_with_name(:out,"Q")
        @circuit.add and_gate=AndGate.new
        q=reg.port_with_name(:out,"Q")
        q.connect and_gate.port_with_name(:in,"i1")
        cond_port.connect and_gate.port_with_name(:in,"i2")
        and_gate_out=and_gate.port_with_name(:out,"f")
        #--- ending state
        reg_end=@code_reg_h[s_to.name]
        # is there a or gate connected to D input, already ?
        unless (d=reg_end.port_with_name(:in,"D")).connections.any?
          @circuit.add or_gate=OrNGate.new
          f=or_gate.port_with_name(:out,'f')
          f.connect d
        else
          wire_or_to_reg=reg_end.port_with_name(:in,"D").connections.first
          or_gate=wire_or_to_reg.pin.circuit
        end
        arity=or_gate.arity
        or_gate.add input=Port.new("i#{arity}",:in)
        and_gate_out.connect input
      end
    end

    def build_cond_rec expr
      case expr
      when Ident
        ident=expr
        unless sig=@symtable[ident.str]
          @circuit.add sig=Signal.new(ident.str)
          @symtable[ident.str]=sig
        end
        return sig
      when Parenth
        return build_cond_rec(expr.expr)
      when BinaryOp
        binop=expr
        gate_klass=binop.op.to_s.capitalize
        @circuit.add gate=Object.const_get("RTL_IR::"+gate_klass+"Gate").new
        i1=build_cond_rec(binop.lhs)
        i2=build_cond_rec(binop.rhs)
        i1.connect gate.port_with_name(:in,'i1')
        i2.connect gate.port_with_name(:in,'i2')
        return gate.port_with_name(:out,'f') # a port
      when Not
        unary=expr
        @circuit.add gate=NotGate.new
        e=build_cond_rec(unary.expr)
        e.connect gate.port_with_name(:in,'i')
        return gate.port_with_name(:out,'f')
      when Token
        if expr.val=="None"
          @circuit.add cst=Constant.new(expr.val.to_i) # a special port
          return cst
        else
          raise "NIY : build_cond_rec for token #{expr}"
        end
      when Indexed
        indexed=expr
        ident=indexed.lhs.str
        unless sig=@symtable[ident]
          @circuit.add sig=Signal.new(ident)
          @symtable[ident]=sig
        end
        @circuit.add slice=BitSlice.new(indexed.rhs..indexed.rhs)
        sig.connect slice.port_with_name(:in,"i")
        return slice.port_with_name(:out,"f")
      when IntLit
        lit=expr
        @circuit.add cst=Constant.new(lit.value.to_i)
        return cst
      else
        raise "NIY : #{expr.class} '#{expr}'"
      end
    end
  end
end
