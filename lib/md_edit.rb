#!/usr/bin/env ruby

# file: md_edit.rb


require 'line-tree'
require 'phrase_lookup'


class MdEdit

  attr_reader :sections
  
  # pass in an MD document
  #
  def initialize(md)
    
    s, @filename = if md.lines.length == 1 and File.exists? md then
      [File.read(md), md]
    else
      md
    end
    
    load_sections(s)
    
  end
  
  def update(heading, value)

    key = @sections.keys.grep(/#{heading.downcase}/i).first

    old_value = @sections[key].flatten.join("\n\n")
    @s.sub!(key + "\n\n" + old_value, value)
    load_sections(@s)
    
    save()
    
  end
  
  alias edit update

  def find(s)
    key = @sections.keys.grep(/#{s.downcase}/i).first
    [key, @sections[key]]
  end
    
  def query(s)    
    @pl.q s    
  end    
  
  alias q query
  
  def to_h()
    @h
  end

  def to_s()
    @s
  end
  
  private
  
  def load_sections(raw_s)
    
    # strip out any new lines gaps which are greater than 1    
    s = raw_s.strip.gsub(/\n\s*\n\s*\n\s*/,"\n\n")
    
    @sections = parse s

    @h =  @sections.keys.inject({}) do |r,x|
      r.merge(x.sub(/^#+ +/,'').downcase => 5 - x.count('#'))
    end      
    
    @pl = PhraseLookup.new @h        
    @s = s
    
  end
    
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
    
    return h  
    
  end
  
  def save()
    File.write @filename, @s if @filename
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