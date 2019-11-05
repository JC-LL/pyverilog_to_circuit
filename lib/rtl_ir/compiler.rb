require_relative 'version'
require_relative 'control_parser'
require_relative 'control_builder'
require_relative 'dataflow_parser'
require_relative 'dataflow_builder'

module RTL

  class Compiler
    attr_accessor :options

    def initialize
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
      datapath=DataflowBuilder.new.build(ast_dataflow)
    end

  end
end
