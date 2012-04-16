require File.expand_path '../test_helper', __FILE__

context 'Parser' do
  setup do
    @graph1 = <<'EOF'
      A---B---C topic
     /
D---E---F---G master
EOF

    @graph2 = <<'EOF'
               B'---C' topic
              /
D---E---A'---F master
EOF

    @graph3 = <<'EOF'
o---o---o---o---o  master
    |            \
    |             o'--o'--o'  topic
     \
      o---o---o---o---o  next
EOF

    @graph4 = <<'EOF'
      A---B---C topic
     /         \
D---E---F---G---H master
EOF
  end

  test 'parses nodes' do
    graph = AsciiDag.parse @graph1

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
    graph = AsciiDag.parse @graph2

    assert_equal [15, 2], find_node(graph, "B'").position
    assert_equal [20, 2], find_node(graph, "C'").position
    assert_equal [8, 0], find_node(graph, "A'").position
    assert_equal [13, 0], find_node(graph, 'F').position
  end

  test 'does not count edges as nodes' do
    ['-', '/', '|', '\\'].each do |char|
      (1..4).each do |i|
        graph_name = "@graph#{i}"
        graph = AsciiDag.parse self.instance_variable_get(graph_name)
        node = find_node(graph, char)
        assert_nil node, "Found unexpected node #{node.inspect} in #{graph_name}"
      end
    end
  end

  test 'handles multiple nodes with the same label' do
    graph = AsciiDag.parse @graph3

    os = find_all_nodes graph, 'o'
    assert_equal 10, os.length

    o_primes = find_all_nodes graph, "o'"
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
    graph = AsciiDag.parse @graph4

    c = find_node graph, 'C'
    g = find_node graph, 'G'
    h = find_node graph, 'H'
    assert_equal [c, g], h.parents
  end

  test 'nodes get unique IDs' do
    ids = {}
    AsciiDag.parse(@graph3).nodes.each do |node|
      assert !ids.has_key?(node.id), "Found duplicate IDs: #{node.inspect}, #{ids[node.id].inspect}"
      ids[node.id] = node
    end
  end

  test 'branch labels are separate from nodes' do
    graph = AsciiDag.parse @graph1

    master = graph.branch_labels.find { |l| l.label == 'master' }
    assert master
    assert_nil find_node(graph, 'master')
  end

  test 'treats tabs as 8 spaces' do
    graph = AsciiDag.parse <<'EOF'
		E-------F
		 \       \
		  G---H---I---J
			       \
				L--M
EOF

    l = find_node graph, 'L'
    j = find_node graph, 'J'
    assert_equal [j], l.parents
  end

  test 'recognizes branch label arrows' do
    graph = AsciiDag.parse <<'EOF'
         o--o--o <-- Branch A
        /
 o--o--o <-- master
        \
         o--o--o <-- Branch B
EOF

    assert_nil find_node(graph, '<')

    branch_a = find_branch_label graph, 'Branch A'
    assert_not_nil branch_a
    assert_equal [17, 4], branch_a.position

    master = find_branch_label graph, 'master'
    assert_not_nil master
    assert_equal [9, 2], master.position

    branch_b = find_branch_label graph, 'Branch B'
    assert_not_nil branch_b
    assert_equal [17, 0], branch_b.position
  end

  test 'should allow colons in branch labels' do
    graph = AsciiDag.parse <<'EOF'
 o--o--O--o--o--o <-- origin
        \        \
         t--t--t--m <-- their branch:
EOF

    assert_nil find_node(graph, '<')

    their_branch = find_branch_label graph, 'their branch:'
    assert_not_nil their_branch
    assert_equal [20, 0], their_branch.position
  end

  test 'should replace apostrophes with primes' do
    graph = AsciiDag.parse @graph2
    a = find_node graph, "A'"
    assert_equal "A&#8242;", a.dot_label
  end

  test 'should only follow edges in allowed directions' do
    graph = AsciiDag.parse <<'EOF'
G-Y-G-W-W-W-X-X-X-X
	   \ /
	    W-W-B
	   /
Y---G-W---W
 \ /   \
Y-Y     X-X-X-X
EOF

    xs = find_all_nodes graph, 'X'
    ws = find_all_nodes graph, 'W'

    x = xs[4]
    w = ws[6]
    assert_equal [w], x.parents

    w2 = ws[2]
    w3 = ws[3]
    assert_equal [w2], w3.parents
  end

  test 'should follow pipe underneath slash' do
    graph = AsciiDag.parse <<'EOF'
                 H'--I'--J'  topicB
                /
                | E---F---G  topicA
                |/
    A---B---C---D  master
EOF

    h = find_node graph, "H'"
    d = find_node graph, 'D'
    assert_equal [d], h.parents
  end

  test 'should treat disconnected numbers as labels' do
    graph = AsciiDag.parse <<'EOF'
1 2 3
A-B-C
     \6 7 8
      F-G-H
1   2/
D---E
EOF

    six = find_branch_label graph, '6'
    assert_not_nil six

    seven = find_node graph, '7'
    assert_nil seven
  end

  test 'should treat numbers with parents as nodes' do
    graph = AsciiDag.parse <<'EOF'
		 o---o---o---B
		/
	---o---1---o---o---o---A
EOF

    one = find_node graph, '1'
    assert_not_nil one
    os = find_all_nodes graph, 'o'
    assert_equal 7, os.length

    assert_equal [one], os[1].parents
    assert_equal [os[0]], one.parents
  end

  test 'should treat numbers that are parents as nodes' do
    graph = AsciiDag.parse <<'EOF'
	       o---o---o---o---C
	      /
	     /   o---o---o---B
	    /   /
	---2---1---o---o---o---A
EOF

    two = find_node graph, '2'
    assert_not_nil two
  end

  test 'allows hyphens in arrowed branch labels' do
    graph = AsciiDag.parse <<'EOF'
 P---o---o---M---x---x---W---x
  \         /
   A---B---C----------------D---E   <-- fixed-up topic branch
EOF

    label = find_branch_label graph, 'fixed-up topic branch'
    assert_not_nil label
  end

  test 'should remove quotes from branch labels' do
    graph = AsciiDag.parse <<'EOF'
            "master"
        o---o
             \                    "topic"
              o---o---o---o---o---o
EOF

    label = find_branch_label graph, 'master'
    assert_equal 'master', label.label
    assert_equal 'master', label.dot_label
  end

  test 'should not merge nodes with adjacent quoted branch labels' do
    graph = AsciiDag.parse <<'EOF'
                                "topicB"
               o---o---o---o---o---* (pretend merge)
              /                   /
             /o---o---o----------'
            |/        "topicA"
        o---o"master"
             \                    "topic"
              o---o---o---o---o---o
EOF

    os = find_all_nodes graph, 'o'
    o = os[7]
    assert_equal [12, 2], o.position
    assert_equal 'o', o.label
    assert_equal [os[6]], o.parents

    master = find_branch_label graph, 'master'
    assert_not_nil master
  end

  test 'should allow asterisks in node names' do
    graph = AsciiDag.parse <<'EOF'
    ---Z---o---X--...---o---A---o---o---Y*--...---o---B*--D*
EOF

    b = find_node graph, 'B*'
    d = find_node graph, 'D*'
    assert_equal [b], d.parents
  end

  test 'should allow number-suffixed node names' do
    graph = AsciiDag.parse <<'EOF'
    r1---r2---r3 remotes/git-svn
                \
                 A---B master
EOF

    r1 = find_node graph, 'r1'
    r2 = find_node graph, 'r2'
    assert_equal [], r1.parents
    assert_equal [r1], r2.parents
  end

  test 'should allow number-with-prime-suffixed node names' do
    graph = AsciiDag.parse <<'EOF'
    r1---r2'--r3' remotes/git-svn
      \
       r2---r3---A---B master
EOF

    r1 = find_node graph, 'r1'
    r2prime = find_node graph, "r2'"
    assert_equal [], r1.parents
    assert_equal [r1], r2prime.parents
  end
end
