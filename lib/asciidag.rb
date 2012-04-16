require 'coreext/string'

module AsciiDag
  def self.parse(text)
    branch_labels = []
    nodes = []
    nodes_by_position = {}
    add_node = lambda do |node|
      return if node.nil?
      nodes << node
      nodes_by_position[node.position] = node
    end

    lines = text.gsub("\t", ' ' * 8).split("\n").reverse
    lines.each_with_index do |line, y|
      branch_label = find_and_remove_branch_label(line, y)
      branch_labels << branch_label unless branch_label.nil?

      i = 0
      while i < line.length
        x = line.index NODE_REGEXP, i
        break if x.nil?
        label = line.substring_after(x)[NODE_REGEXP]
        add_node.call Node.new(label, x, y)
        i = x + label.length
      end
    end
    nodes.each do |node|
      node.parents = find_parents node.position, nodes_by_position, lines
    end
    all_parents = nodes.inject({}) do |parents, node|
      node.parents.each do |parent|
        parents[parent.id] = 1
      end
      parents
    end
    nodes, disconnected_nodes = nodes.partition { |node| node.parents.length > 0 || all_parents.has_key?(node.id) }
    branch_labels += disconnected_nodes
    Graph.new nodes, branch_labels
  end

  class Graph
    attr_reader :nodes, :branch_labels

    def initialize(nodes, branch_labels)
      @nodes = nodes
      @branch_labels = branch_labels
    end

    def dot
      result = []
      result << 'digraph {'
      result << '  graph [splines=true, overlap=false];'
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

    @@id_number = 0

    def initialize(label, x, y)
      @label = label
      @position = [x, y]
      @parents = []
      @id = "node#{@@id_number}"
      @@id_number += 1
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

  def self.find_and_remove_branch_label(line, y)
      match = line.match BRANCH_LABEL_REGEXP
      return if match.nil?
      group_number = match.captures.index { |c| !c.nil? } + 1
      label = match[group_number]
      x = match.offset(group_number)[0]
      line[BRANCH_LABEL_REGEXP] = ''
      match = line.match ARROW_REGEXP
      unless match.nil?
        # Position the label where the arrow starts.
        x = match.offset(1)[0]
        line[ARROW_REGEXP] = ''
      end
      Node.new label, x, y
  end

  def self.find_parents(position, nodes_by_position, lines)
    # This hash maps edge characters to options for where to search next to
    # follow the edge. Each option consists of an array that contains three
    # elements: a position delta (represented as a sub-array containing
    # separate X and Y deltas), a set of valid edge characters that could be
    # found after applying the position delta (or 'n', to signify that a node
    # could be found), and a valid Y direction. The special :initial entry
    # represents what to do on the first step of the algorithm.
    next_steps = {
      '-' => [
        [[-1, 0], '-n', :either],
      ],
      '\\' => [
        [[-1, 1], '-\\|n', :up],
      ],
      '|' => [
        [[0, 1], '|n', :up],
        [[0, -1], '|n', :down],
      ],
      '/' => [
        [[-1, -1], '/-|n', :down],
        # At least one diagram in the Git docs contains a pipe directly beneath
        # a slash, so we allow it.
        [[0, -1], '|', :down],
      ],
      :initial => [
        [[-1, 1], '\\', :up],
        [[-1, 0], '-', :either],
        [[-1, -1], '/', :down],
      ],
    }

    inner = nil
    continue_search = lambda do |current_character, position, direction|
      x, y = position
      valid_steps = next_steps[current_character].select { |_, _, dir| [dir, :either].include? direction }
      valid_steps.collect do |delta, cs, dir|
        dx, dy = delta
        strictest_direction = dir == :either ? direction : dir
        inner.call [x + dx, y + dy], cs, strictest_direction
      end.reject { |p| p.nil? }
    end

    inner = lambda do |position, valid_edge_characters, valid_direction|
      x, y = position
      return unless x >= 0 && y >= 0
      parent = nodes_by_position[[x, y]]
      return parent unless parent.nil? || !valid_edge_characters.chars.include?('n')
      line = lines[y]
      return if line.nil?
      ord = line[x]
      return if ord.nil?
      if ord.chr =~ /[-\/\\|]/
        return unless valid_edge_characters.chars.include?(ord.chr)
        continue_search.call ord.chr, position, valid_direction
      else
        # This might be part of a multi-character node label.
        return unless valid_edge_characters.chars.include?('n')
        start_x = line.index_of_earliest_match_ending_at NODE_REGEXP, x
        return if start_x.nil? || start_x + line.substring_after(start_x)[NODE_REGEXP].length != x + 1
        inner.call [start_x, y], 'n', valid_direction
      end
    end
    continue_search.call(:initial, position, :either).flatten
  end

  NODE_REGEXP = /\w(?:\d)?['*]?|\*/
  BRANCH_LABEL_REGEXP = /(?:(\w{3,}.*?)|"(.+?)"|(\(.+?\)))\s*$/
  ARROW_REGEXP = /\s+(<--)\s+$/
  PIXELS_PER_CHARACTER_X = 25
  PIXELS_PER_CHARACTER_Y = 40
end
