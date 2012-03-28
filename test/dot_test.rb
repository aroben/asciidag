require File.expand_path '../test_helper', __FILE__

context 'dot output' do
  test 'generates basic digraph' do
    text = <<-EOF
      A---B---C topic
     /
D---E---F---G master
EOF
    assert_equal '', Picasso.parse(text).dot
  end
end
