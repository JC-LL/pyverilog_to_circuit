require_relative 'generic_lexer'

module RTL

  class ControlLexer < GenericLexer
    def initialize
      super
      ignore /\s/ # not \s+
      #....keywords
      keyword 'FSM'
      keyword 'signal'
      keyword 'Condition'
      keyword 'list'
      keyword 'length'
      keyword 'None'

      token :trans_end  => /\-\-\>/
      token :trans_start=> /\-\-/
      token :comma      => /\,/
      token :colon      => /\:/

      token :eq         => /\=\=/
      token :neq        => /\!\=/
      token :gte        => /\>\=/
      token :gt         => /\>/
      token :lte        => /\<\=/
      token :lt         => /\</
      token :not        => /\!/
      token :and        => /\&\&/

      token :add        => /\+/
      token :sub        => /\-/
      token :exp        => /(\*\*)|\^/
      token :mul        => /\*/
      token :div        => /\//
      token :mod        => /\%/
      token :equal      => /\=/

      token :comment    => /#(.*)$/
      token :lparen     => /\(/
      token :rparen     => /\)/
      token :lbrack     => /\[/
      token :rbrack     => /\]/
      token :lbrace     => /\{/
      token :rbrace     => /\}/
      token :dots       => /\.\./
      token :dot        => /\./
      token :id         => /[a-zA-Z_$][a-zA-Z0-9_]*/i

      # literals
      token :verilog_int_lit   => /(\d+)?'([bh])?([\w]+)/
      token :float_lit  => /[-+]?\d+\.\d+/
      token :int_lit    => /(0[b-h])?[-+]?\d+/

    end
  end
end
