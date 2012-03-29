module AsciiDag
  def self.parse(text)
    nodes = []
    nodes_by_position = {}
    add_node = lambda do |node|
      return if node.nil?
      nodes << node
      nodes_by_position[node.position] = node
    end

    lines = text.gsub("\t", ' ' * 8).split("\n").reverse
    lines.each_with_index do |line, y|
      add_node.call find_and_remove_arrowed_branch_label(line, y)

      i = 0
      while i < line.length
        x = line.index NODE_REGEXP, i
        break if x.nil?
        label = line[x, line.length - x][NODE_REGEXP]
        add_node.call Node.new(label, x, y)
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

    def dot
      result = []
      result << 'digraph {'
      result << '  node [shape=circle];'
      nodes.each do |node|
        x, y = node.position
        result << "  #{node.id} [label=\"#{node.label}\", pos=\"#{x * PIXELS_PER_CHARACTER_X},#{y * PIXELS_PER_CHARACTER_Y}\"];"
        node.parents.each do |parent|
          result << "  #{node.id} -> #{parent.id};"
        end
      end
      branch_labels.each do |branch|
        x, y = branch.position
        result << "  #{branch.id} [shape=none, label=\"#{branch.label}\", pos=\"#{x * PIXELS_PER_CHARACTER_X},#{y * PIXELS_PER_CHARACTER_Y}\"];"
      end
      result << '}'
      result.join "\n"
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
      "#<AsciiDag::Node #{id} #{label.inspect} #{position.inspect} #{parents_array.inspect}"
    end
  end

  private

  def self.find_and_remove_arrowed_branch_label(line, y)
      match = line.match ARROWED_BRANCH_LABEL_REGEXP
      return if match.nil?
      label = match[1]
      x = match.offset(1)[0]
      line[ARROWED_BRANCH_LABEL_REGEXP] = ''
      Node.new label, x, y
  end

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
  ARROWED_BRANCH_LABEL_REGEXP = /\s+<-- ([\w\s]+)$/
  PIXELS_PER_CHARACTER_X = 25
  PIXELS_PER_CHARACTER_Y = 40
end
