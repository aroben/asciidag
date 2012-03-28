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

    a = find_node graph, 'A'
    e = find_node graph, 'E'
    assert_equal [6, 2], a.position
    assert_equal [e], a.parents

    b = find_node graph, 'B'
    assert_equal [10, 2], b.position
    assert_equal [a], b.parents

    d = find_node graph, 'D'
    assert_equal [0, 0], d.position
    assert_equal [], d.parents
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
    |            \\
    |             o'--o'--o'  topic
     \\
      o---o---o---o---o  next
EOF

    graph = Picasso.parse text

    assert_nil find_node(graph, '\\')
    assert_nil find_node(graph, '|')

    os = graph.nodes.find_all { |n| n.label == 'o' }
    assert_equal 10, os.length

    o_primes = graph.nodes.find_all { |n| n.label == "o'" }
    assert_equal 3, o_primes.length

    origin = os[5]
    assert_equal [0, 4], origin.position
    assert_equal [], origin.parents

    assert_equal [origin], os[6].parents
    assert_equal [os[6]], os[0].parents
    assert_equal [os[9]], o_primes[0].parents
  end

  test 'merge commits have multiple parents' do
    text = <<-EOF
      A---B---C topic
     /         \\
D---E---F---G---H master
EOF

    graph = Picasso.parse text

    c = find_node graph, 'C'
    g = find_node graph, 'G'
    h = find_node graph, 'H'
    assert_equal [g, c], h.parents
  end
end
