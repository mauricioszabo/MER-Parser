#!/usr/bin/ruby
require 'erb'

TEMPLATE_DIR = File.expand_path(File.join(File.dirname(__FILE__), "templates"))
TAMANHO_FONTE = 10

class Modelo
  attr_reader :nome, :atributos 
  def initialize(nome)
    @nome = nome
    @atributos = []
  end

  def <<(atributo)
    if(atributo[0..1] == '++')
      @atributos << atributo[2..-1] + ": chave primária"
    elsif(atributo[0] == ?+)
      @atributos << atributo[1..-1] + ": chave"
    else
      @atributos << atributo
    end
  end
end

class Relacionamento < Struct.new(:direita, :esquerda, :texto)
  Lado = Struct.new(:nome, :cardinalidade)
  def initialize(params)
    self.esquerda = Lado.new
    self.direita = Lado.new

    self.texto = params[:texto]

    self.esquerda.nome = params[:esquerda]
    self.direita.nome = params[:direita]

    self.esquerda.cardinalidade = params[:c_esquerda]
    self.direita.cardinalidade = params[:c_direita]
  end
end

class Parser
  def initialize(formato, arquivo)
    @formato = formato

    @modelos = []
    @relacionamentos = []

    arquivo.each_line do |linha|
      linha.strip!

      if(linha.empty?)
        @modelo = nil
      else
        if(linha[-1] == ?:)
          @modelo = Modelo.new(linha[0..-2])
          @modelos ||= []
          @modelos << @modelo
        else
          if @modelo
            @modelo << linha
          else
            relacionamento(linha)
          end
        end
      end
    end
  end

  def parse
    erb = ERB.new(File.read("#{TEMPLATE_DIR}/#@formato.erb"))
    erb.result(binding)
  end

  private
  def relacionamento(linha)
    linha = linha.split /\s+/
    cardinalidade = linha[1].split /\s*-\s*/
    @relacionamentos << Relacionamento.new(
      :esquerda => linha[0], :c_esquerda => cardinalidade[0],
      :direita => linha[2], :c_direita => cardinalidade[-1],
      :texto => linha[3..-1].join(" ")
    )
  end
end

if(__FILE__ == $0)
  if(ARGV.size == 1)
    puts Parser.new(ARGV[0], $stdin.read).parse
  elsif(ARGV.size == 2)
    puts Parser.new(ARGV[0], File.read(ARGV[1])).parse
  else
    puts "#{$0} <formato> <arquivo>"
  end
end
