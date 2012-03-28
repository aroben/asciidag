module Picasso
  def self.parse(text)
    nodes = {}
    text.split("\n").each_with_index do |line, y|
      i = 0
      while i < line.length
        x = line.index NODE_REGEXP, i
        break if x.nil?
        node = line[x, line.length - x][NODE_REGEXP]
        nodes[node] = [x, y]
        i = x + node.length
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

  private

  NODE_REGEXP = /[^\s-]+/
end
