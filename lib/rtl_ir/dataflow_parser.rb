require_relative './generic_parser'
require_relative 'dataflow_lexer'
require_relative 'dataflow_ast'

module RTL

  class DataflowParser < GenericParser
    attr_accessor :tokens

    def parse filename
      begin
        str=IO.read(filename)
        @tokens=DataflowLexer.new.tokenize(str)
        #@tokens.each{|tok| p tok}
        ast=parse_all
      rescue Exception => e
         puts "PARSING ERROR : #{e}"
         puts "in source at line/col #{showNext.pos}"
         puts e.backtrace
         abort
      end
    end

    def parse_all
      top=DesignUnit.new
      top.directive=parse_directive()
      top.instance=parse_instance()
      top.terms=parse_terms()
      top.binds=parse_binds()
      return top
    end

    def parse_directive
      expect :Directive
      expect :colon
      expect :newline
      unless showNext.is_a?(:Instance)
        accept_until_newline
      end
    end

    def accept_until_newline
      acceptIt until showNext.is_a? :newline
      acceptIt
    end

    def parse_instance
      expect :Instance
      expect :colon
      expect :newline
      name=parse_instance_parenth
      Instance.new("name" => name)
    end

    def parse_instance_parenth
      expect :lparen
      name=expect(:id).val
      expect :comma
      expect :str_lit
      expect :rparen
      expect :newline
      return name
    end

    def parse_terms
      terms=[]
      expect :Term
      expect :colon
      expect :newline
      while showNext(2).is_a? :Term
        term=parse_node(:Term)
        terms << term
        expect :newline
      end
      terms
    end

    def parse_node head
      #puts "parsing node '#{head}' at #{showNext.pos}"
      pos=showNext.pos
      klass=Object.const_get("RTL::"+head.to_s)
      expect :lparen
      expect head
      attrs=parse_attrs()
      attrs=attrs.reduce({},:merge) if attrs.all?{|e| e.class==Hash}
      node=klass.new(attrs)
      node.pos=pos
      expect :rparen
      node
    end

    def parse_attrs
      attrs=[]
      until showNext.is_a?(:rparen)
        case showNext(2).kind
        when :colon
          attrs << parse_named_attr()
        else
          attrs << parse_attr_value()
        end
      end
      attrs
    end

    def parse_named_attr
      key=expect(:id).val
      expect :colon
      value=parse_attr_value
      if showNext.is_a? :comma # ugly format !
        # value is now an array.
        value=[value]
        while showNext.is_a? :comma
          acceptIt
          value << parse_attr_value
        end
      end
      {key => value}
    end

    def parse_attr_value
      case showNext.kind
      when :id
        ret=parse_id_attr
      when :lparen
        ret=parse_node(showNext(2).val.to_sym)
      when :lbrack
        ret=parse_array
      when :int_lit
        ret="intlit_#{acceptIt.val.to_i}"
      when :verilog_int_lit
        val=acceptIt.val.sub(/\'/,'_')
        ret="vintlit_#{val}"
      else
        raise "unknown attr value '#{showNext}'"
      end
      ret
    end

    def parse_id_attr
      lhs=expect(:id).val
      while showNext.is_a? [:dot]
        acceptIt
        rhs=expect(:id).val
        lhs=Pointed.new(lhs,rhs)
      end
      lhs
    end

    def parse_array
      array=[]
      expect :lbrack
      until showNext.is_a? :rbrack
        str=acceptIt.val # contains '' !
        str.gsub!(/\'/,'')
        array<< str
        acceptIt if showNext.is_a?(:comma)
      end
      expect :rbrack
      array
    end

    def parse_binds
      binds=[]
      expect :Bind
      expect :colon
      expect :newline
      while @tokens.any? and showNext(2).is_a?(:Bind)
        binds << parse_node(:Bind)
        expect :newline
      end
      binds
    end

  end #class parser
end
