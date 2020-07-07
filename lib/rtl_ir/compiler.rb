require_relative 'version'
require_relative 'control_parser'
require_relative 'control_builder'
require_relative 'dataflow_parser'
require_relative 'dataflow_builder'
require_relative 'dataflow_metrics'

module RTL

  class Compiler
    attr_accessor :options
    attr_accessor :dataflow
    def initialize options={}
      @options={}
      banner
    end

    def banner
      puts "RTL compiler version #{VERSION}"
    end

    def compile_fsm filename
      puts "=> compiling fsm '#{filename}'"
      ast_control=ControlParser.new.parse filename
      fsm=ControlBuilder.new.build(ast_control)
    end

    def compile_dataflow filename
      puts "=> compiling dataflow '#{filename}'"
      ast_dataflow=DataflowParser.new.parse filename
      @dataflow=DataflowBuilder.new.build(ast_dataflow)
      evaluate_metrics if options[:metrics]
    end


    def evaluate_metrics
      puts "=> evaluating metrics"
      metrics=DataflowMetrics.new.evaluate(@dataflow)
      pp metrics
    end
  end
end
