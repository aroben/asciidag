module Picasso
  def self.parse(text)
    nodes = []
    lines = text.split "\n"
    lines.each_with_index do |line, row|
      i = 0
      while i < line.length
        x = line.index NODE_REGEXP, i
        break if x.nil?
        label = line[x, line.length - x][NODE_REGEXP]
        nodes << Node.new(label, x, lines.length - row - 1)
        i = x + label.length
      end
    end
    Graph.new nodes
  end

  class Graph
    attr_reader :nodes

    def initialize(nodes)
      @nodes = nodes
    end
  end

  class Node
    attr_reader :label, :position

    def initialize(label, x, y)
      @label = label
      @position = [x, y]
    end
  end

  private

  NODE_REGEXP = /[^\s\-\/]+/
end
