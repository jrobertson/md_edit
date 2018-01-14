#!/usr/bin/env ruby

# file: md_edit.rb


require 'line-tree'
require 'phrase_lookup'


IGNOREWORDS = ['or', 'the', 'of', 'a', 'if', 'to', 'and', 
                'in', 'is', 'are', 'as', 'it', 'at']

class MdEdit

  attr_reader :sections, :phraseslookup
  
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
        
    @s = @s.rstrip + "\n\n" + s.sub(/^(?=\w)/,'## ').sub(/#+ [a-z]/)\
        {|x| x.upcase}.sub(/(?!=^\n)$/,"\n\n")
    load_sections(@s)        
    save()
    
    :created    
  end
  
  # specify a heading to delete a section
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
    
    value = raw_value.gsub(/\r/,'').chomp + "\n"

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
    
    key = @sections.keys\
        .grep(/#{s.downcase.gsub('(','\(').gsub(')','\)')}/i).first
    return unless key
    
    headings = key.lines.first.split(/ > /)
    title = "%s %s" % ['#' * headings.length, headings.last]
    a = [title, @sections[key].join]
    
    heading ? a.join : a
  end
    
  def query(s, full_trail: false, limit: 10)    
    
    puts 'query() s: ' + s.inspect if @debug
    
    results = []
    
    r = @headingslookup.q s
    puts 'query() r: ' + r.inspect if @debug
    
    if r and r.any? then
      
      results = if full_trail then
        r
      else
        r.map do |x|
          headings = x.split(' > ')
          headings.length > 1 ? headings[1..-1].join(' > ') : headings[0]
        end.reject(&:empty?)
      end
      
    end
    
      
    r2 = @phraseslookup.q s, search_tags: true
    
    if r2 and r2.any? then
      
      a = r2.sort_by {|x| -x.length} 
      
      # attempt to remove duplicate results from the 1 section

      a2 = a.group_by {|x| x[/\[[^\]]+\]/]}

      a2.each do |k,v|
        
        s4 = v.first[/\]\s*(.*)/mi,1]          

        index = s4 =~ /#{s}/mi
        
        s2 = make_snippet(s4, index, words: [2,2])          
        
        v[1..-1].each do |x| 
          
          s5 = x[/\]\s*(.*)/,1]
          index2 = s5 =~ /#{s}/
          
          if index2 then
            s3 = make_snippet(s5, index2, words: [2,2])
            v.delete x if s2 =~ /#{s3}/
          else
            v.delete x
          end
        end

      end

    end
    
    if a2 then
            
      h = a2.values.flatten(1).group_by {|x| x[/\[[^\]]+\]/]}

      
      phrases_found = h.to_a.flat_map do |raw_heading,v|
        
        
        # get rid of results which are almost duplicate (contain a 
        # subset of text from the 1st result)
        
        phrases = v.map {|x| x[/\] +(.*)/,1]}
        filtered_phrases = phrases[1..-1].reject {|x| phrases[0].include? x }

        filtered_phrases.unshift(phrases[0])
        
        # get rid of the top level heading from the heading trailing
        
        heading = if raw_heading =~ / > / then
          
          raw_heading[1..-2].split(' > ')[1..-1].join(' > ')
        else
          raw_heading[1..-2]
        end        
        
        filtered_phrases.map {|phrase| "[%s] %s" % [heading, phrase] }

      end
      
      
      results.concat phrases_found if phrases_found    
      
    end

    results.take limit

  end    
  
  alias q query
  
  def to_outline(bullets: false)
    
    a = indentor(@s.scan(/^#+ [^\n]+/).join("\n"))
                        .lines.map {|x| x.sub(/#+ +/,'')}
    bullets ? a.map{|x| x.sub(/\b/,'- ')} : a.join
    
  end
  
  def to_h()
    @h
  end

  def to_s()
    @s
  end
  
  private
  
  # returns a hash object; each key contains the heading as well as a phrase
  #
  def build_keyword_list(s, heading)
    
    a = s.split.uniq.flat_map do |raw_word|

      i, pos = 0, []

      w = raw_word[/\w{2,}/]
      
      next if IGNOREWORDS.include? w
      next unless w

      (pos << (s[i..-1] =~ /#{w}/i); i += pos[-1] + 1) while s[i..-1][/#{w}/i]

      pos[1..-1].inject([pos[0]]) {|r,x| r << r.last + x + 1 }

      pos.map do |x| 
        
        start = x-15
        start = 0 if start < 0
        snippet = make_snippet(s, start)
        
        "[%s] %s | %s %s" % [heading, snippet, w.downcase, 
                             heading.scan(/\w+/).join(' ').downcase]
      end


    end
    
    a
    
  end
  
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
  
  def load_sections(s)
    
    @sections = parse s

    h =  @sections.keys.inject({}) do |r,x|
      r.merge(x.sub(/^#+ +/,'').downcase => 5 - x.count('#'))
    end      
    puts 'h: ' + h.inspect if @debug
    @headingslookup = PhraseLookup.new h
    @h = h.to_a.map {|k,v| [k.split(' > ').last, v]}.to_h
    @s = s 
    
    phrases = @sections.flat_map do |heading, raw_value|

      a = raw_value.take_while {|x| x.is_a? String}

      next unless a and a.join.strip.length > 0
      #next if a.nil? or a.join.strip.empty?
      build_keyword_list(a.join.strip, heading).compact.map do |s|
        [s, 4 - heading.count('>')]
      end
      
    end

    @phraseslookup = PhraseLookup.new phrases.compact.to_h
    
  end
  
  def make_snippet(raw_s, start, words: [2, 8])
    
    s = raw_s.gsub(/\n/,' ')
    take_words_behind(s[0..start], words: words[0]) + 
        take_words(s[start+1..-1], words: words[-1])
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

        [head + "\n", r]

      else
        x.flatten.join
      end

    end

  end

  def take_words(s, words: 8)

    r = s[/^(?:\S+\s+){#{words}}/m]
    r ? r : s

  end

  def take_words_behind(s, words: 2)

    r = s[/(?:\s+\S+){#{words}}$/m]
    r ? r : s

  end
  
end