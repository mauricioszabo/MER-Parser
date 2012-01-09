#!/usr/bin/ruby
require 'erb'

class Model
  attr_reader :name, :attributes 

  def initialize(name)
    @name = name
    @attributes = []
  end

  def <<(attribute)
    if(attribute[0..1] == '++')
      @attributes << attribute[2..-1] + " [primary key]"
    elsif(attribute[0] == ?+)
      @attributes << attribute[1..-1] + " [key]"
    else
      @attributes << attribute
    end
  end
end

class Relationship < Struct.new(:right, :left, :text)
  Side = Struct.new(:name, :cardinality)
  def initialize(params)
    self.left = Side.new
    self.right = Side.new

    self.text = params[:text]

    self.left.name = params[:left]
    self.right.name = params[:right]

    self.left.cardinality = params[:c_left]
    self.right.cardinality = params[:c_right]
  end
end

class Parser
  TEMPLATE_DIR = File.expand_path(File.join(File.dirname(__FILE__), "templates"))

  def initialize(format, arquivo)
    @format = format

    @models = []
    @relationships = []

    arquivo.each_line do |line|
      line.strip!

      if(line.empty?)
        @model = nil
      else
        if(line[-1] == ?:)
          @model = Model.new(line[0..-2])
          @models ||= []
          @models << @model
        else
          if @model
            @model << line
          else
            relationship(line)
          end
        end
      end
    end
  end

  def relationship(line)
    line = line.split /\s+/
    cardinality = line[1].split /\s*-\s*/
    @relationships << Relationship.new(
      :left => line[0], :c_left => cardinality[0],
      :right => line[2], :c_right => cardinality[-1],
      :text => line[3..-1].join(" ")
    )
  end
  private :relationship

  def parse
    erb = ERB.new(File.read("#{TEMPLATE_DIR}/#@format.erb"))
    erb.result(binding)
  end
end

if(__FILE__ == $0)
  if(ARGV.size == 1)
    puts Parser.new(ARGV[0], $stdin.read).parse
  elsif(ARGV.size == 2)
    puts Parser.new(ARGV[0], File.read(ARGV[1])).parse
  else
    puts "#{$0} <format> [<file>]
      if <file> is not given, it will read from STDIN."
  end
end
