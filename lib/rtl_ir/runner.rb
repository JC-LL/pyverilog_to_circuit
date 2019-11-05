require "optparse"

require_relative "compiler"

module RTL

  class Runner

    def self.run *arguments
      new.run(arguments)
    end

    def run arguments
      compiler=Compiler.new
      compiler.options = args = parse_options(arguments)
      $options=compiler.options

      if filename=args[:fsm_filename]
        compiler.compile_fsm filename
      elsif filename=args[:dataflow_filename]
        compiler.compile_dataflow filename
      else
        puts "need a file : rtl_ir_compiler <file>"
      end
    end

    private
    def parse_options(arguments)

      size=arguments.size

      parser = OptionParser.new

      options = {}

      parser.on("-h", "--help", "Show help message") do
        puts parser
        exit(true)
      end

      parser.on("-v", "--version", "Show version number") do
        puts VERSION
        exit(true)
      end

      parser.on("-f FILE", "--fsm FILE", "compile FSM") do |filename|
        options[:fsm_filename]=filename
      end

      parser.on("-d FILE", "--dataflow FILE", "compile dataflow") do |filename|
        options[:dataflow_filename]=filename
      end

      parser.on("--verbose", "verbose mode") do
        options[:verbose]=true
        $verbose=true
      end

      parser.parse!(arguments)

      options[:filename]=arguments.shift

      if arguments.any?
        puts "WARNING : superfluous arguments : #{arguments}"
      end

      if size==0
        puts parser
      end

      options
    end
  end
end
