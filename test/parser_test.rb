require File.expand_path '../test_helper', __FILE__

context 'Parser' do
  test 'parses nodes' do
    text = <<-EOF
      A---B---C topic
     /
D---E---F---G master
EOF
    graph = Picasso.parse text
    assert_nil find_node(graph, '/')
    assert_equal [6, 2], find_node(graph, 'A').position
    assert_equal [10, 2], find_node(graph, 'B').position
    assert_equal [0, 0], find_node(graph, 'D').position
  end

  test 'parses nodes with prime names' do
    text = <<-EOF
               B'---C' topic
              /
D---E---A'---F master
EOF
    graph = Picasso.parse text
    assert_equal [15, 2], find_node(graph, "B'").position
    assert_equal [20, 2], find_node(graph, "C'").position
    assert_equal [8, 0], find_node(graph, "A'").position
    assert_equal [13, 0], find_node(graph, 'F').position
  end

  test 'handles multiple nodes with the same label' do
    text = <<-EOF
o---o---o---o---o  master
    |            \
    |             o'--o'--o'  topic
     \
      o---o---o---o---o  next
EOF

    graph = Picasso.parse text
    os = graph.nodes.find_all { |n| n.label == 'o' }
    o_primes = graph.nodes.find_all { |n| n.label == "o'" }
    assert_equal 10, os.length
    assert_equal 3, o_primes.length
  end
end
