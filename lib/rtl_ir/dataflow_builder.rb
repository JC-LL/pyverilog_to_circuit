require_relative './generic_parser'
require_relative 'control_lexer'
require_relative 'control_ast'
require_relative 'circuit'
require_relative 'circuit_dot_printer'

module RTL

  class DataflowBuilder

    attr_accessor :ast,:symtable

    # returns a circuit
    def build dataflow
      puts "=> building dataflow"
      dataflow.binds.size
      @ast=dataflow
      @symtable={}
      @circuit=Circuit.new ast.instance.name
      build_symtable
      build_io
      build_parameters
      build_bindings
      insert_regs
      connect_reg_recirculation
      @circuit.to_dot
      #@circuit.view
      puts "  - circuit size (components) : #{@circuit.components.size}"
      return @circuit
    end

    def build_symtable
      puts "  - building symbol table"
      @symtable={}
      ast.terms.each{|term| @symtable[term.name.to_s]=term}
    end

    def build_io
      @signals_h={}
      ast.terms.each do |term|
        case type=term.type.first
        when 'Input'
          @circuit.add sig=Port.new(term.name,:in)
        when 'Output'
          @circuit.add sig=Port.new(term.name,:out)
        when 'Rename'
          @circuit.add sig=Signal.new(term.name)
        when 'Reg'
          @circuit.add sig=Signal.new(name=term.name)
          if name.to_s.match(/_reg_/)
            sig.params[:clocked]=true
          end
          if name.to_s.match(/ap_NS_fsm/)
            sig.params[:clocked]=true
          end

        when 'Wire'
          @circuit.add sig=Signal.new(term.name)
        when 'Parameter'
          @circuit.add sig=Signal.new(term.name.to_s)
        else
          raise "NIY build_io '#{type}'"
        end
        @signals_h[sig.name.to_s]=sig if sig
      end
    end

    def build_parameters
      params=ast.terms.select{|term| term.type.first=='Parameter'}
      params.each do |param|
        "searching value for param '#{param.name.to_s}'"
        bind=ast.binds.find{|bind| bind.dest.to_s==param.name.to_s}
        raise "value for parameter '#{params.name.to_s}' not found" unless bind
        sig=@signals_h[param.name.to_s]
        source=build_tree(bind.tree)
        source.connect sig
      end
    end

    def build_bindings
      puts "  - build bindings"
      @ast.binds.each do |bind|
        name=bind.dest.to_s
        term=symtable[name]
        sig=@signals_h[name]
        port=build_tree(bind.tree)
        port.connect sig
      end
    end

    def build_tree tree
      cst=term=branch=part_select=operator=concat=tree
      case tree
      when IntConst
        @circuit.add port=Constant.new(cst.value)
      when Terminal
        name=term.name.to_s
        port=@signals_h[name]
      when Branch
        @circuit.add mux=Mux.new
        cond=build_tree(branch.Cond)
        cond.connect mux.port_with_name(:in,'sel')
        i0=build_tree(branch.True)
        i0.connect mux.port_with_name(:in,'i0')
        if branch.False
          i1=build_tree(branch.False)
          i1.connect mux.port_with_name(:in,'i1')
        end
        port=mux.port_with_name(:out,'f')
      when Partselect
        name=part_select.Var.name.to_s
        sig=@signals_h[name]
        msb=part_select.MSB.int_value
        lsb=part_select.LSB.int_value
        @circuit.add slice=BitSlice.new(lsb..msb)
        sig.connect slice.port_with_name(:in,'i')
        port=slice.port_with_name(:out,'f')
      when Concat
        @circuit.add group=BitGroup.new
        case concat.Next
        when Array
          concat.Next.each_with_index do |e,idx|
            source_port=build_tree(e)
            group.add input=Port.new("i#{idx}",:in)
            source_port.connect input
          end
        else
          source_port=build_tree(concat.Next)
          group.add input=Port.new("i0",:in)
          source_port.connect input
        end
        port=group.port_with_name(:out,'f')
      when Operator
        case type=operator.type
        when "Eq","And","Or","Times","Eql","Plus","Minus","GreaterThan","LessThan","Xor","Sll"
          klass=Object.const_get("RTL::"+type+"Gate")
          @circuit.add comp=klass.new
          i1=build_tree(operator.next[0])
          i1.connect comp.port_with_name(:in,'i1')
          i2=build_tree(operator.next[1])
          i2.connect comp.port_with_name(:in,'i2')
          port=comp.port_with_name(:out,'f')
        else
          raise "NIY build_tree operator '#{type}'"
        end
      else
        raise "NIY build_bindings '#{tree}'"
      end
      return port
    end

    def insert_regs
      puts "  - inserting regs..."
      @circuit.components.each do |comp|
        #puts "- component #{comp.name}"
        comp.outputs.each do |output|
          #puts "  - output #{output.name}"
          to_delete=[]
          output.connections.each do |wire|
            if wire.pout.params[:clocked]
              puts "\t-clocked #{wire.pout.name}"
              @circuit.add reg=Reg.new
              d=reg.port_with_name(:in,"D")
              q=reg.port_with_name(:out,"Q")
              wire.pin.connect d
              q.connect wire.pout
              wire.pout.params[:clocked]=false
              to_delete << wire
            end
          end
          to_delete.each{|wire| output.connections.delete(wire)}
        end
      end
    end

    def connect_reg_recirculation
      puts "  - processing reg recirculation"
      muxes=@circuit.components.select{|comp| comp.is_a? Mux}
      muxes.each do |mux|
        #puts "\t-mux #{mux.name}"
        i0=mux.port_with_name(:in,"i0")
        i1=mux.port_with_name(:in,"i1")
        if i0.connections.empty?
          puts "\tmux #{mux.name} : i0 need a register as input"
          reg=find_next_reg(mux)
          reg.port_with_name(:out,"Q").connect i0
          puts "\t\treg #{reg.name} found and connected" if reg
        end
        if i1.connections.empty?
          puts "\tmux #{mux.name} : i1 need a register as input"
          reg=find_next_reg(mux)

          reg.port_with_name(:out,"Q").connect i1
          puts "\t\treg #{reg.name} found and connected" if reg
        end
      end
    end

    def find_next_reg component
      if component.is_a? Reg
        return component
      else
        component.outputs.each do |output|
          output.connections.each do |wire|
            next_component=wire.pout.circuit
            return find_next_reg(next_component)
          end
        end
      end
    end

  end
end
