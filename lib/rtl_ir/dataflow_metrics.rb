module RTL
  class DataflowMetrics
    def evaluate circuit
      metrics={}
      metrics[:nb_components]     = circuit.components.size
      metrics[:nb_inputs]         = circuit.ports[:in].size
      metrics[:nb_outputs]        = circuit.ports[:out].size
      metrics[:nb_signals]        = circuit.signals.size
      metrics[:nb_regs]           = (regs=circuit.components.select{|comp| comp.is_a?(Reg)}).size
      metrics[:nb_muxes]          = (muxes=circuit.components.select{|comp| comp.is_a?(Mux)}).size
      metrics[:avg_inputs_fanout] = circuit.ports[:in].map{|input| input.connections.size}.sum.to_f / circuit.ports[:in].size
      metrics[:avg_signal_fanout] = circuit.signals.collect{|sig| sig.connections.size}.sum.to_f / circuit.signals.size
      metrics[:avg_regs_fanout]   = regs.map{|reg| reg.port_with_name(:out,"Q").connections.size}.sum.to_f / regs.size
      metrics[:avg_muxs_fanin]    = muxes.map{|mux| mux.inputs.size}.sum.to_f / muxes.size
      metrics[:nb_comparators]    = (circuit.components.select{|comp| [EqlGate,GreaterThanGate,LessThanGate].include? comp.class}).size
      metrics[:nb_arith_ops]      = (circuit.components.select{|comp| [TimesGate,PlusGate,MinusGate].include? comp.class}).size
      metrics
    end
  end
end
