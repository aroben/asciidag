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
end
