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
        result << "  #{node.id} [label=\"#{node.dot_label}\", pos=\"#{x * PIXELS_PER_CHARACTER_X},#{y * PIXELS_PER_CHARACTER_Y}\"];"
        node.parents.each do |parent|
          result << "  #{node.id} -> #{parent.id};"
        end
      end
      branch_labels.each do |branch|
        x, y = branch.position
        result << "  #{branch.id} [shape=none, label=\"#{branch.dot_label}\", pos=\"#{x * PIXELS_PER_CHARACTER_X},#{y * PIXELS_PER_CHARACTER_Y}\"];"
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

    def dot_label
      label.gsub "'", '&#8242;'
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
      label = match[2]
      # Position the label where the arrow starts.
      x = match.offset(1)[0]
      line[ARROWED_BRANCH_LABEL_REGEXP] = ''
      Node.new label, x, y
  end

  def self.find_parents(position, nodes_by_position, lines)
    # This is a hash that maps edge characters to options for where to search
    # next to follow the edge. Each option consists of an array that contains
    # two elements: a position delta (represented as a sub-array containing
    # separate X and Y deltas), and a set of valid edge characters that could
    # be found after applying the position delta. The special :initial entry
    # represents what to do on the first step of the algorithm.
    next_steps = {
      '-' => [
        [[-1, 0], '-'],
      ],
      '\\' => [
        [[-1, 1], '-\\|'],
      ],
      '|' => [
        [[0, 1], '|'],
      ],
      '/' => [
        [[-1, -1], '/-'],
      ],
      :initial => [
        [[-1, 1], '\\'],
        [[-1, 0], '-'],
        [[-1, -1], '/'],
      ],
    }

    inner = nil
    continue_search = lambda do |current_character, position|
      x, y = position
      next_steps[current_character].collect do |d, cs|
        dx, dy = d
        inner.call [x + dx, y + dy], cs
      end.reject { |p| p.nil? }
    end

    inner = lambda do |position, valid_edge_characters|
      x, y = position
      return unless x >= 0 && y >= 0
      parent = nodes_by_position[[x, y]]
      return parent unless parent.nil?
      line = lines[y]
      return if line.nil?
      ord = line[x]
      return if ord.nil?
      case ord.chr
      when /[-\/\\|]/
        return unless valid_edge_characters.chars.include?(ord.chr)
        continue_search.call ord.chr, position
      when NODE_REGEXP
        # This might be part of a multi-character node label.
        start_x = line.rindex(/[\s\-\/\\|]/, x)
        return if start_x.nil?
        inner.call [start_x + 1, y], ''
      end
    end
    continue_search.call(:initial, position).flatten
  end

  NODE_REGEXP = /[^\s\-\/\\|]+/
  ARROWED_BRANCH_LABEL_REGEXP = /\s+(<--) ([\w\s:]+)$/
  PIXELS_PER_CHARACTER_X = 25
  PIXELS_PER_CHARACTER_Y = 40
end
