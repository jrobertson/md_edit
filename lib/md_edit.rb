#!/usr/bin/env ruby

# file: md_edit.rb


require 'line-tree'
require 'phrase_lookup'


class MdEdit

  attr_reader :sections
  
  # pass in a Markdown document or a Markdown filename
  #
  def initialize(md, debug: false, root: 'Thoughts')
    
    @debug = debug
    
    s, @filename = if md.lines.length == 1 then

      File.write(md, "# #{root}\n\n") unless File.exists? md 
      File.exists?(md) ? [File.read(md), md] : md

    else

      md

    end
    
    load_sections(s)
    
  end
  
  def create(s)
        
    @s << "\n\n" + s.sub(/^(?=\w)/,'## ').sub(/#+ [a-z]/){|x| x.upcase}\
        .sub(/(?!=^\n)$/,"\n\n")
    load_sections(@s)        
    save()
    
    :created    
  end
  
  # specify a heeading to delete a section
  #
  def delete(s)
    
    key = @sections.keys.grep(/#{s.downcase}/i).first
    old_value = @sections[key].flatten.join
    heading = last_heading(key)
    old_section =  heading + old_value
    
    @s.sub!(old_section, '')    
    load_sections(@s)        
    save()
    
    :deleted
  end  
  
  # update a section by heading title e.g. ## To-do\n\n[ ] Vacuum the bedroom
  #
  def update(raw_value, heading: nil )
    
    value = raw_value.gsub(/\r/,'')

    title = (heading ? heading : value.lines.first.chomp)[/#+ +(.*)/,1]

    key = @sections.keys.grep(/#{title.downcase}/i).first

    return unless key

    old_value = @sections[key].flatten.join
    puts 'old_value: ' + old_value.inspect if @debug

    heading = last_heading(key)
    old_section =  value =~ /^#+/ ? heading + old_value : old_value 
    puts 'old_section: ' + old_section.inspect if @debug

    @s.sub!(old_section, value)
    puts '@s: ' + @s.inspect if @debug    
    load_sections(@s)    
    
    save()
    
    :updated
    
  end
  
  alias edit update

  def find(s, heading: true)
    
    key = @sections.keys.grep(/#{s.downcase}/i).first
    return unless key
    
    headings = key.lines.first.split(/ > /)
    title = "%s %s" % ['#' * headings.length, headings.last]
    a = [title, @sections[key].join]
    
    heading ? a.join : a
  end
    
  def query(s)    
    @pl.q s    
  end    
  
  alias q query
  
  def to_h()
    @h
  end
  
  def to_outline(bullets: false)
    
    a = indentor(@s.scan(/^#+ [^\n]+/).join("\n"))
                        .lines.map {|x| x.sub(/#+ +/,'')}
    bullets ? a.map{|x| x.sub(/\b/,'- ')} : a.join
    
  end

  def to_s()
    @s
  end
  
  private
  
  def indentor(s)
    
    a = s.split(/(?<=\n)(?=#+)/)

    a.map.with_index do |x, i|

      # get the indentation level
      indent = x[/^#+/].count('#') - 1

      lines = x.lines
      lines.first.prepend('  ' * indent) +
        lines[1..-1].map {|y| ('  ' * indent) + '  ' + y}.join 
    end.join
    
  end
  
  def last_heading(key)
    
    a = key.lines.first.split(/ > /)
    "%s %s" % ['#' * a.length, a.last]
    
  end
  
  def load_sections(raw_s)
    
    # strip out any new lines gaps which are greater than 1    
    s = raw_s #.strip.gsub(/\n\s*\n\s*\n\s*/,"\n\n")
    
    @sections = parse s

    @h =  @sections.keys.inject({}) do |r,x|
      r.merge(x.sub(/^#+ +/,'').downcase => 5 - x.count('#'))
    end      
    
    @pl = PhraseLookup.new @h        
    @s = s 
    
  end
    
  def parse(markdown)
    
    s = indentor(markdown)
    puts "s: \n" + s if @debug
    a = LineTree.new(s, ignore_blank_lines: false, ignore_newline: false).to_a
    puts 'a: ' + a.inspect if @debug
    h = {}
    scan a, h

    return h  
    
  end
  
  def save()
    File.write @filename, @s if @filename
  end
 
  def scan(a, h={}, trail=[])
    
    a.map do |x|

      raw_head = x.first

      if raw_head =~ /^#/ then

        head = raw_head[/^[^\n]+/]              
        
        fullkey = trail + [head[/#+ +(.*)/,1]]
        key = fullkey.join(" > ")
        h[key] = nil
        r = scan(x[1..-1], h, fullkey)      

        h[key] =  ["\n"] + r

        [head, r]

      else
        x.flatten.join
      end

    end

  end  


end