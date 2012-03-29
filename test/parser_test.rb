require File.expand_path '../test_helper', __FILE__

context 'Parser' do
  setup do
    @graph1 = AsciiDag.parse <<-EOF
      A---B---C topic
     /
D---E---F---G master
EOF

    @graph2 = AsciiDag.parse <<-EOF
               B'---C' topic
              /
D---E---A'---F master
EOF

    @graph3 = AsciiDag.parse <<-EOF
o---o---o---o---o  master
    |            \\
    |             o'--o'--o'  topic
     \\
      o---o---o---o---o  next
EOF

    @graph4 = AsciiDag.parse <<-EOF
      A---B---C topic
     /         \\
D---E---F---G---H master
EOF

    @graph5 = AsciiDag.parse <<-EOF
		E-------F
		 \\       \\
		  G---H---I---J
			       \\
				L--M
EOF
  end

  test 'parses nodes' do
    a = find_node @graph1, 'A'
    e = find_node @graph1, 'E'
    assert_equal [6, 2], a.position
    assert_equal [e], a.parents

    b = find_node @graph1, 'B'
    assert_equal [10, 2], b.position
    assert_equal [a], b.parents

    d = find_node @graph1, 'D'
    assert_equal [0, 0], d.position
    assert_equal [], d.parents
  end

  test 'parses nodes with prime names' do
    assert_equal [15, 2], find_node(@graph2, "B'").position
    assert_equal [20, 2], find_node(@graph2, "C'").position
    assert_equal [8, 0], find_node(@graph2, "A'").position
    assert_equal [13, 0], find_node(@graph2, 'F').position
  end

  test 'does not count edges as nodes' do
    ['-', '/', '|', '\\'].each do |char|
      (1..4).each do |i|
        graph_name = "@graph#{i}"
        graph = self.instance_variable_get(graph_name)
        node = find_node(graph, char)
        assert_nil node, "Found unexpected node #{node.inspect} in #{graph_name}"
      end
    end
  end

  test 'handles multiple nodes with the same label' do
    os = @graph3.nodes.find_all { |n| n.label == 'o' }
    assert_equal 10, os.length

    o_primes = @graph3.nodes.find_all { |n| n.label == "o'" }
    assert_equal 3, o_primes.length

    origin = os[5]
    assert_equal [0, 4], origin.position
    assert_equal [], origin.parents

    assert_equal [origin], os[6].parents
    assert_equal [os[6]], os[0].parents
    assert_equal [os[9]], o_primes[0].parents
    assert_equal [o_primes[0]], o_primes[1].parents
  end

  test 'merge commits have multiple parents' do
    c = find_node @graph4, 'C'
    g = find_node @graph4, 'G'
    h = find_node @graph4, 'H'
    assert_equal [g, c], h.parents
  end

  test 'nodes get unique IDs' do
    ids = {}
    @graph3.nodes.each do |node|
      assert !ids.has_key?(node.id), "Found duplicate IDs: #{node.inspect}, #{ids[node.id].inspect}"
      ids[node.id] = node
    end
  end

  test 'branch labels are separate from nodes' do
    master = @graph1.branch_labels.find { |l| l.label == 'master' }
    assert master
    assert_nil find_node(@graph1, 'master')
  end

  test 'treats tabs as 8 spaces' do
    l = find_node @graph5, 'L'
    j = find_node @graph5, 'J'
    assert_equal [j], l.parents
  end
end
