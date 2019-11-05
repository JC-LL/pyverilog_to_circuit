class GenericParser

  def acceptIt
    tok=tokens.shift
    puts "consuming #{tok.val} (#{tok.kind})" if @verbose
    tok
  end

  def showNext k=1
    tokens[k-1]
  end

  def expect kind
    if (actual=showNext.kind)!=kind
      puts "ERROR at #{showNext.pos}. Expecting #{kind}. Got #{actual}"
      show_error(showNext.pos)
      raise
      #abort
    else
      return acceptIt()
    end
  end

  def more?
    !tokens.empty?
  end

  def show_error pos
    puts line=IO.readlines(@filename)[pos.first-1]
    puts "~"*(pos.last-2)+ ">|"
  end

end
