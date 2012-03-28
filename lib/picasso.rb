module Picasso
  def self.parse(text)
    nodes = []
    nodes_by_position = {}
    lines = text.split("\n").reverse
    lines.each_with_index do |line, y|
      i = 0
      while i < line.length
        x = line.index NODE_REGEXP, i
        break if x.nil?
        label = line[x, line.length - x][NODE_REGEXP]
        node = Node.new label, x, y
        nodes << node
        nodes_by_position[node.position] = node
        i = x + label.length
      end
    end
    nodes.each do |node|
      node.parents = find_parents node.position, nodes_by_position, lines
    end
    Graph.new nodes
  end

  class Graph
    attr_reader :nodes, :branch_labels

    def initialize(nodes)
      nodes.each_with_index do |node, i|
        node.id = "node#{i}"
      end
      @branch_labels, @nodes = nodes.partition { |node| node.label =~ /[a-z]{2,}/ }
    end
  end

  class Node
    attr_reader :label, :position
    attr_accessor :id, :parents

    def initialize(label, x, y)
      @label = label
      @position = [x, y]
      @parents = []
    end

    def inspect
      parents_array = parents.collect { |parent| parent.label + parent.position.inspect }
      "#<Picasso::Node #{id} #{label.inspect} #{position.inspect} #{parents_array.inspect}"
    end
  end

  private

  def self.find_parents(position, nodes_by_position, lines)
    positions_to_search = lambda do |position|
      x = position[0] - 1
      below = position[1] - 1
      above = position[1] + 1
      (below..above).collect { |y| [x, y] }.reject do |(x, y)|
        x < 0 || y < 0
      end
    end

    inner = lambda do |position|
      x, y = position
      parent = nodes_by_position[[x, y]]
      return parent unless parent.nil?
      line = lines[y]
      return if line.nil?
      ord = line[x]
      return if ord.nil?
      case ord.chr
      when '-'
        inner.call [x - 1, y]
      when '\\'
        inner.call [x - 1, y + 1]
      when '|'
        inner.call [x, y + 1]
      when '/'
        inner.call [x - 1, y - 1]
      when NODE_REGEXP
        # This might be part of a multi-character node label.
        start_x = line.rindex(/[\s\-\/\\|]/, x)
        return if start_x.nil?
        inner.call [start_x + 1, y]
      end
    end
    positions_to_search.call(position).collect { |p| inner.call p }.reject { |p| p.nil? }
  end

  NODE_REGEXP = /[^\s\-\/\\|]+/
end
