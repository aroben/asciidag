require File.expand_path '../test_helper', __FILE__

context 'Parser' do
  test 'parses nodes' do
    text = <<-EOF
      A---B---C topic
     /
D---E---F---G master
EOF
    graph = Picasso.parse text
    assert !graph.nodes.has_key?('/')
    assert_equal [6, 2], graph.nodes['A']
    assert_equal [10, 2], graph.nodes['B']
    assert_equal [0, 0], graph.nodes['D']
  end

  test 'parses nodes with prime names' do
    text = <<-EOF
               B'---C' topic
              /
D---E---A'---F master
EOF
    graph = Picasso.parse text
    assert_equal [15, 2], graph.nodes["B'"]
    assert_equal [20, 2], graph.nodes["C'"]
    assert_equal [8, 0], graph.nodes["A'"]
    assert_equal [13, 0], graph.nodes['F']
  end
end
