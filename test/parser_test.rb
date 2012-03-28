require File.expand_path '../test_helper', __FILE__

context 'Parser' do
  test 'parses nodes' do
    graph = <<-EOF
      A---B---C topic
     /
D---E---F---G master
EOF
    nodes = Picasso.parse graph
    assert_equal [6, 0], nodes['A']
    assert_equal [10, 0], nodes['B']
    assert_equal [0, 2], nodes['D']
  end

  test 'parses nodes with prime names' do
    graph = <<-EOF
               B'---C' topic
              /
D---E---A'---F master
EOF
    nodes = Picasso.parse graph
    assert_equal [15, 0], nodes["B'"]
    assert_equal [20, 0], nodes["C'"]
    assert_equal [8, 2], nodes["A'"]
    assert_equal [13, 2], nodes['F']
  end
end
