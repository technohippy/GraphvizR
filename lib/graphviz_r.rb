# GraphvizR is graphviz adapter for Ruby, and it can:
# * generate a graphviz dot file, and
# * generate an image file directly.
#
# A sample code to generate dot file is:
#
#   gvr = GraphvizR.new 'sample'
#   gvr.graph [:label => 'example', :size => '1.5, 2.5'] 
#   gvr.alpha >> gvr.beta
#   gvr.beta >> gvr.delta
#   gvr.delta >> gvr.gamma
#   gvr.to_dot
#
# The code generates a dot file look like:
#
#   digraph sample {
#     graph [label = "example", size = "1.5, 2.5"];
#     beta [shape = box];
#     alpha -> beta;
#     beta -> delta;
#     delta -> gamma;
#   }
#
# == Node
#
# A node can be created by method calling or array accessing to GraphvizR instance. In short,
# both <tt>gvr.abc</tt> and <tt>gvr[:abc]</tt> generate the <tt>abc</tt> node in dot file.
#
# == Edge
#
# An edge is generated by <tt>&gt;&gt;</tt> of <tt>-</tt> method calling to a node; the former
# generate a directed graph while the latter a undirected one. For example,
#   gvr = GraphvizR.new 'sample'
#   gvr.alpha >> gvr.beta
# generates
#   digraph sample {
#     alpla -> beta
#   }
# while
#   gvr = GraphvizR.new 'sample'
#   gvr.alpha - gvr.beta
# generates
#   graph sample {
#     alpla -- beta
#   }
#
# == Grouping Nodes
#
# When one node is the root of some nodes, you can aggregate the children by using an array.
# For example,
#   gvr = GraphvizR.new 'sample'
#   gvr.alpha >> [gvr.beta, gvr.gamma, gvr.delta]
# generates
#   digraph sample {
#     alpha -> {beta; gamma; delta;}
#   }
#
# == Consective Edges
#
# You can write:
#   gvr = GraphvizR.new 'sample'
#   gvr.alpha >> gvr.beta >> gvr.gamma >> gvr.delta
# instead of doing:
#   gvr = GraphvizR.new 'sample'
#   gvr.alpha >> gvr.beta
#   gvr.beta >> gvr.gamma
#   gvr.gamma >> gvr.delta
#
# == Graph Attributes
# 
# Attributes are specified by Hash in []. Thus, to set the fillcolor of a node abc, one would use
#   gvr = GraphvizR.new 'sample'
#   gvr.abc [:fillcolor => :red]
#
# Similarly, to set the arrowhead style of an edge abc -> def, one would use
#   (gvr.abc >> gvr.def) [:arrowhead => :diamond]
#
# As you can expect, to set graph attributes, one would use
#   gvr.graph [:label => 'example', :size => '1.5, 2.5'] 
#
# == Record
#
# To set a record label on a node, you can use ordinary [] method.
#   gvr.node1 [:label => "<p_left> left|<p_center>center|<p_right> right"]
#
# To access a record in a node, you can use method calling whose argumemts is the name of a record.
#   gvr.node1(:p_left) >> gvr.node2
#
# Accordingly, a full example looks like:
#   gvr = GraphvizR.new 'sample'
#   gvr.node [:shape => :record]
#   gvr.node1 [:label => "<p_left> left|<p_center>center|<p_right> right"]
#   gvr.node2
#   gvr.node1(:p_left) >> gvr.node2
#   gvr.node2 >> gvr.node1(:p_center)
#   (gvr.node2 >> gvr.node1(:p_right)) [:label => 'record']
#   gvr.to_dot
#
# == Rank
#
# Ranks of nodes can be set as the same value for other nodes.
#   gvr.rank :same, [gvr.a, gvr.b, gvr.c]
# means node a, b, and c has same rank value and generages:
#   {rank = same; a; b; c;};
#
# == Clusters
#
# Cluster is a way to construct hierarchical graph in graphviz. GraphvizR allows you to use 
# clusters by means of method calling with a block which has one argument. For example,
#   gvr = GraphvizR.new 'sample'
#   gvr.cluster0 do |c0|
#     c0.graph [:color => :blue, :label => 'area 0', :style => :bold]
#     c0.a >> c0.b
#     c0.a >> c0.c
#   end
#   gvr.cluster1 do |c1|
#     c1.graph [:fillcolor => '#cc9966', :label => 'area 1', :style => :filled]
#     c1.d >> c1.e
#     c1.d >> c1.f
#   end
#   (gvr.a >> gvr.f) [:lhead => :cluster1, :ltail => :cluster0]
#   gvr.b >> gvr.d
#   (gvr.c >> gvr.d) [:ltail => :cluster0]
#   (gvr.c >> gvr.f) [:lhead => :cluster1]
#   gvr.to_dot
# generates
#   digraph sample {
#     subgraph cluster0 {
#       graph [color = blue, label ="area 0", style = bold];
#       a -> b;
#       a -> c;
#     }
#     subgraph cluster1 {
#       graph [fillcolor = "#cc9966", label = "area 1", style = filled];
#       d -> e;
#       d -> f;
#     }
#     a -> f [lhead = cluster1, ltail = cluster0];
#     b -> d;
#     c -> d [ltail = cluster0];
#     c -> f [lhead = cluster1];
#
class GraphvizR 
  VERSION = '0.5.1'
  INDENT_UNIT = '  '

  attr_reader :statements, :graph_type

  # This initialzes a GraphvizR instance.
  # +name+:: the name of the graph
  # +parent+:: a parent graph is given when this graph is a subgraph.
  # +indent+:: indent level when this instance is converted to rdot.
  def initialize(name, parent=nil, indent=0)
    @name = name
    @parent = parent
    @graph_type = 'digraph'
    @indent = indent
    @directed = true
    @statements = []
  end

  # if block is not given, this generates a node.
  # if block given, generates a subgraph.
  def [](name, *args, &block)
    if block
      subgraph = self.class.new name, self, @indent + 1
      block.call subgraph
      @statements << subgraph
    else
      node = Node.new name, args, self
      @statements << node
      node
    end
  end

  ['digraph', 'graph', 'subgraph'].each do |graph_type|
    define_method :"to_#{graph_type}" do
      @graph_type = graph_type
    end
  end

  # set all nodes as same level
  def rank(same, nodes=[])
    group = NodeGroup.new nodes, :rank => same
    nodes.size.times do
      @statements.pop
    end
    @statements << group
    group
  end

  # If <tt>format</tt> is 'dot', a dot string is generated. Otherwise, this generates image file
  # in the given format, such as 'png', 'gif', 'jpg', and so on. To know correctly, please see 
  # the specification of graphviz: http://www.graphviz.org/doc/info/output.html
  def data(format='png')
    format = format.to_s
    if format == 'dot'
      to_dot
    else
      begin
        gv = IO.popen "dot -q -T#{format || 'png'}", "w+"
        gv.puts to_dot
        gv.close_write
        gv.read
      ensure
        gv.close
      end
    end
  end

  # store image data created from this instance to given file.
  def output(filename=nil, format='png')
    img = data(format)
    File.open(filename || "#{@name}.#{format || 'png'}", "w+") do |file|
      file.write img
    end
  end

  # convert this instance to dot
  def to_dot(indent=@indent)
    to_subgraph if @parent
    dot = INDENT_UNIT * indent
    dot += "#{@graph_type} #{@name} {\n"
    @statements.each do |statement|
      dot += statement.to_dot(indent + 1)
    end
    dot += INDENT_UNIT * indent
    dot += "}\n"
    dot
  end

  # redirect to [] method.
  def method_missing(name, *args, &block) #:nodoc:
    self.send(:"[]", name, *args, &block)
  end

  # This represents graphviz node.
  class Node
    attr_reader :name, :parent
    
    def initialize(name, args, parent)
      @parent = parent
      @name = name
      @edge = nil
      @port = nil
      @attributes = {}
      unless args.empty?
        arg = args[0]
        if arg.is_a? Symbol
          @port = arg
          @attributes = {}
        elsif arg.is_a? Array
          @port = nil
          @attributes = arg[0]
        end
      end
    end

    # if blank between node and attributes does not exist, this method is used.
    # otherwise GraphvizR#[] is used.
    # ex) gvr.graph[:label => 'example', :size => '1.5, 2.5']
    def [](attributes)
      @attributes = attributes
    end

    # generate an edge from self to given node.
    # this generates a directed edge.
    def >>(node)
      @parent.to_digraph
      @edge = Edge.new self, node, @parent
    end

    # generate an edge from self to given node.
    # this generates a undirected edge.
    def -(node)
      @parent.to_graph
      @edge = Edge.new self, node, @parent, '--'
    end

    # to string
    def to_s
      if @port
        "#{@name}:#{@port}"
      else
        @name
      end
    end

    # to dot format
    def to_dot(indent=0)
      attributes = @attributes.empty? ? '' : ' ' + @attributes.to_dot
      "#{INDENT_UNIT * indent}#{@name}#{attributes};\n"
    end
  end

  # This represents a graphviz edge.
  class Edge
    def initialize(from, to, parent, arrow='->')
      @attributes = {}
      @nodes = [from, to]
      @arrow = arrow
      @parent = parent
      (from.is_a?(Array) ? from : [from]).size.times do
        @parent.statements.pop
      end
      (to.is_a?(Array) ? to : [to]).size.times do
        @parent.statements.pop
      end
      @parent.statements << self
    end

    # set attributes for the edge
    def [](attributes)
      @attributes = attributes
    end

    # consequent directed edge
    def >>(node)
      @parent.to_digraph
      (node.is_a?(Array) ? node : [node]).size.times do
        @parent.statements.pop
      end
      @nodes << node
      self
    end

    # consequent undirected edge
    def -(node)
      @parent.to_graph
      (node.is_a?(Array) ? node : [node]).size.times do
        @parent.statements.pop
      end
      @nodes << node
      self
    end

    # to dot
    def to_dot(indent)
      edge = @nodes.map{|e| e.is_a?(Array) ? e.to_dot : e.to_s}.join(" #{@arrow} ")
      attributes = @attributes.empty? ? '' : ' ' + @attributes.to_dot
      "#{INDENT_UNIT * indent}#{edge}#{attributes};\n"
    end
  end

  # this represent a group of nodes
  class NodeGroup
    def initialize(nodes, opts)
      @nodes = nodes
      @opts = opts
    end

    def to_dot(indent)
      options = @opts.to_a.map{|e| "#{e[0]} = #{e[1]};"}.join ' '
      nodes = @nodes.map{|e| "#{e.to_s};"}.join ' '
      "#{INDENT_UNIT * indent}{#{options} #{nodes}};\n"
    end
  end
end

class Symbol #:nodoc:
  def <=>(other)
    to_s <=> other.to_s
  end

  def to_dot
    to_s
  end
end

class String #:nodoc:
  def to_dot
    inspect.gsub('\e', '\l')
  end
end

class Hash #:nodoc:
  def to_dot
    "[#{to_a.sort.map{|e| "#{e[0].to_dot} = #{e[1].to_dot}"}.join(', ')}]"
  end
end

class Array #:nodoc:
  def >>(node)
    raise NoMethodError if empty? or not node.is_a? GraphvizR::Node
    
    parent = self[0].parent
    parent.to_digraph
    GraphvizR::Edge.new self, node, parent
  end

  def to_dot
    "{#{self.map{|e| e.to_s}.join('; ')};}"
  end
end

