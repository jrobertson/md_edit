#!/usr/bin/env ruby

# file: md_edit.rb


require 'line-tree'
require 'phrase_lookup'


class MdEdit

  # pass in an MD document
  #
  def initialize(s=nil)
    
    if s then
      
      parse s

      h =  @h.keys.inject({}) do |r,x|
        r.merge(x.sub(/^#+ +/,'').downcase => 5 - x.count('#'))
      end      
      
      @pl = PhraseLookup.new h
      
    end
  end

  def find(s)
    key = @h.keys.grep(/#{s.downcase}/i).first
    [key, @h[key]]
  end
    
  def query(s)    
    @pl.q s    
  end    
  
  alias q query
  
  def to_h()
    @h
  end  
  
  private
    
  def parse(s)

    a = s.split(/(?=\n#+)/)

    a2 = a.map.with_index do |x, i|

      # get the indentation level
      indent = x[/^#+/].count('#') - 1

      lines = x.lstrip.lines
      lines.first.prepend('  ' * indent) +
        lines[1..-1].map {|y| ('  ' * indent) + '  ' + y}.join + "\n"
    end

    a3 = LineTree.new(a2.join).to_a

    h = {}

    a4 = scan a3, h
    @h = h  
    
  end
 
  def scan(a, h={})

    a.map do |x|

      head = x.first

      if head =~ /#/ then
        
        r = scan(x[1..-1], h)
        h[head] = r
        [head, r]
        
      else
        x.first
      end

    end
  end  

end
