dir = File.dirname(File.expand_path(__FILE__))
$TEST_DIR = File.dirname(File.expand_path(__FILE__))
$TESTING = true
require 'asciidag'

##
# test/spec/mini 5
# http://gist.github.com/307649
# chris@ozmm.org
#
def context(*args, &block)
  return super unless (name = args.first) && block
  require 'test/unit'
  klass = Class.new(defined?(ActiveSupport::TestCase) ? ActiveSupport::TestCase : Test::Unit::TestCase) do
    def self.test(name, &block)
      define_method("test_#{name.to_s.gsub(/\W/,'_')}", &block) if block
    end
    def self.xtest(*args) end
    def self.context(*args, &block) instance_eval(&block) end
    def self.setup(&block)
      define_method(:setup) { self.class.setups.each { |s| instance_eval(&s) } }
      setups << block
    end
    def self.setups; @setups ||= [] end
    def self.teardown(&block) define_method(:teardown, &block) end
  end
  (class << klass; self end).send(:define_method, :name) { name.gsub(/\W/,'_') }
  klass.class_eval &block
end

def find_branch_label(graph, label)
  return graph.branch_labels.find { |n| n.label == label }
end

def find_node(graph, label)
  return graph.nodes.find { |n| n.label == label }
end

def find_all_nodes(graph, label)
  return graph.nodes.find_all { |n| n.label == label }
end
