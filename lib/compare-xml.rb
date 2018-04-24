require 'compare-xml/version'
require 'nokogiri'

module CompareXML
  # default options used by the module; all of these can be overridden
  DEFAULTS_OPTS = {
    # when true, trims and collapses whitespace in text nodes and comments to a single space
    # when false, all whitespace is preserved as it is without any changes
    collapse_whitespace: true,

    # when true, attribute order is not important (all attributes are sorted before comparison)
    # when false, attributes are compared in order and comparison stops on the first mismatch
    ignore_attr_order: true,

    # when true, children of elements are always compared
    # when false, children of elements are not compared if the root is different
    force_children: false,

    # when true, children of elements are never compared
    # when false, children of elements are compared if root is different or see force_children
    ignore_children: false,

    # contains an array of user specified strings that is used to ignore any attributes
    # whose content contains a string from this array (e.g. "good automobile" contains "mobile")
    ignore_attr_content: [],

    # contains an array of user-specified CSS rules used to perform attribute exclusions
    # for this to work, a CSS rule MUST contain the attribute to be excluded,
    # i.e. a[href] will exclude all "href" attributes contained in <a> tags.
    ignore_attrs: [],

    # contains an array of user specified strings that is used to ignore any attributes
    # whose name contains a string from this array (e.g. "good automobile" contains "mobile")
    ignore_attrs_by_name: [],

    # when true ignores XML and HTML comments
    # when false, all comments are compared to their counterparts
    ignore_comments: true,

    # contains an array of user-specified CSS rules used to perform node exclusions
    ignore_nodes: [],

    # when true, ignores all text nodes (although blank text nodes are always ignored)
    # when false, all text nodes are compared to their counterparts (except the empty ones)
    ignore_text_nodes: false,

    # when true, provides a list of all error messages encountered in comparisons
    # when false, execution stops when the first error is encountered with no error messages
    verbose: false
  }.freeze

  class << self
    # used internally only in order to differentiate equivalence for inequivalence
    EQUIVALENT = 1

    # a list of all possible inequivalence types for nodes
    # these are returned in the differences array to differentiate error types.
    MISSING_ATTRIBUTE = 2 # attribute is missing its counterpart
    MISSING_NODE = 3 # node is missing its counterpart
    UNEQUAL_ATTRIBUTES = 4 # attributes are not equal
    UNEQUAL_COMMENTS = 5 # comment contents are not equal
    UNEQUAL_DOCUMENTS = 6 # document types are not equal
    UNEQUAL_ELEMENTS = 7 # nodes have the same type but are not equal
    UNEQUAL_NODES_TYPES = 8 # nodes do not have the same type
    UNEQUAL_TEXT_CONTENTS = 9 # text node contents are not equal

    ##
    # Determines whether two XML documents or fragments are equal to each other.
    # The two parameters could be any type of XML documents, or fragments
    # or node sets or even text nodes - any subclass of Nokogiri::XML::Node.
    #
    #   @param [Nokogiri::XML::Element] n1 left node element
    #   @param [Nokogiri::XML::Element] n2 right node element
    #   @param [Hash] opts user-overridden options
    #   @param [Hash] childopts user-overridden options used for the child nodes
    #   @param [Bool] diffchildren use different options for the child nodes
    #
    #   @return true if equal, [Array] differences otherwise
    #
    def equivalent?(n1, n2, opts = {}, childopts = {}, diffchildren = false)
      opts = DEFAULTS_OPTS.merge(opts)
      childopts = DEFAULTS_OPTS.merge(childopts)
      differences = []
      result = diffchildren ? compareNodes(n1, n2, opts, differences, childopts, diffchildren) : compareNodes(n1, n2, opts, differences)
      opts[:verbose] ? differences : result == EQUIVALENT
    end

    private

    ##
    # Compares two nodes for equivalence. The nodes could be any subclass
    # of Nokogiri::XML::Node including node sets and document fragments.
    #
    #   @param [Nokogiri::XML::Node] n1 left node
    #   @param [Nokogiri::XML::Node] n2 right node
    #   @param [Hash] opts user-overridden options
    #   @param [Array] differences inequivalence messages
    #   @param [Hash] childopts user-overridden options used for the child nodes
    #   @param [Bool] diffchildren use different options for the child nodes
    #   @param [int] status comparison status code (EQUIVALENT by default)
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareNodes(n1, n2, opts, differences, childopts = {}, diffchildren = false, status = EQUIVALENT)
      if n1.class == n2.class
        case n1
        when Nokogiri::XML::Comment
          status = compareCommentNodes(n1, n2, opts, differences)
        when Nokogiri::HTML::Document
          status = diffchildren ? compareDocumentNodes(n1, n2, opts, differences, childopts, diffchildren) : compareDocumentNodes(n1, n2, opts, differences)
        when Nokogiri::XML::Element
          status = diffchildren ? compareElementNodes(n1, n2, opts, differences, childopts, diffchildren) : compareElementNodes(n1, n2, opts, differences)
        when Nokogiri::XML::Text
          status = compareTextNodes(n1, n2, opts, differences)
        else
          raise 'Comparison only allowed between objects of type Nokogiri::XML::Node and Nokogiri::XML::NodeSet.' unless n1.is_a?(Nokogiri::XML::Node) || n1.is_a?(Nokogiri::XML::NodeSet)
          status = compareChildren(n1.children, n2.children, opts, differences)
        end
      elsif n1.nil? || n2.nil?
        status = MISSING_NODE
        addDifference(n1, n2, n1, n2, opts, differences)
      else
        status = UNEQUAL_NODES_TYPES
        if n1.is_a? Nokogiri::XML::Text
          addDifference(n1.parent, n2, n1, n2, opts, differences)
        elsif n2.is_a? Nokogiri::XML::Text
          addDifference(n1, n2.parent, n1, n2, opts, differences)
        else
          addDifference(n1, n2, n1, n2, opts, differences)
        end
      end
      status
    end

    ##
    # Compares two nodes of type Nokogiri::HTML::Comment.
    #
    #   @param [Nokogiri::XML::Comment] n1 left comment
    #   @param [Nokogiri::XML::Comment] n2 right comment
    #   @param [Hash] opts user-overridden options
    #   @param [Array] differences inequivalence messages
    #   @param [int] status comparison status code (EQUIVALENT by default)
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareCommentNodes(n1, n2, opts, differences, status = EQUIVALENT)
      return true if opts[:ignore_comments]
      t1 = n1.content
      t2 = n2.content
      if opts[:collapse_whitespace]
        t1 = collapse(t1)
        t2 = collapse(t2)
      end
      unless t1 == t2
        status = UNEQUAL_COMMENTS
        addDifference(n1.parent, n2.parent, t1, t2, opts, differences)
      end
      status
    end

    ##
    # Compares two nodes of type Nokogiri::HTML::Document.
    #
    #   @param [Nokogiri::XML::Document] n1 left document
    #   @param [Nokogiri::XML::Document] n2 right document
    #   @param [Hash] opts user-overridden options
    #   @param [Array] differences inequivalence messages
    #   @param [Hash] childopts user-overridden options used for the child nodes
    #   @param [Bool] diffchildren use different options for the child nodes
    #   @param [int] status comparison status code (EQUIVALENT by default)
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareDocumentNodes(n1, n2, opts, differences, childopts = {}, diffchildren = false, status = EQUIVALENT)
      if n1.name == n2.name
        status = diffchildren ? compareChildren(n1.children, n2.children, childopts, differences, diffchildren) : compareChildren(n1.children, n2.children, opts, differences)
      else
        status = UNEQUAL_DOCUMENTS
        addDifference(n1, n2, n1, n2, opts, differences)
      end
      status
    end

    ##
    # Compares two sets of Nokogiri::XML::NodeSet elements.
    #
    #   @param [Nokogiri::XML::NodeSet] n1_set left set of Nokogiri::XML::Node elements
    #   @param [Nokogiri::XML::NodeSet] n2_set right set of Nokogiri::XML::Node elements
    #   @param [Hash] opts user-overridden options
    #   @param [Array] differences inequivalence messages
    #   @param [Bool] diffchildren use different options for the child nodes
    #   @param [int] status comparison status code (EQUIVALENT by default)
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareChildren(n1_set, n2_set, opts, differences, diffchildren = false, status = EQUIVALENT)
      i = 0; j = 0
      return if opts[:ignore_children]
      while i < n1_set.length || j < n2_set.length
        if !n1_set[i].nil? && nodeExcluded?(n1_set[i], opts)
          i += 1 # increment counter if left node is excluded
        elsif !n2_set[j].nil? && nodeExcluded?(n2_set[j], opts)
          j += 1 # increment counter if right node is excluded
        else
          result = diffchildren ? compareNodes(n1_set[i], n2_set[j], opts, differences, opts, diffchildren) : compareNodes(n1_set[i], n2_set[j], opts, differences)
          status = result unless result == EQUIVALENT

          # return false so that this subtree could halt comparison on error
          # but neighbours of parents' subtrees could still be compared (in verbose mode)
          return false if [UNEQUAL_NODES_TYPES, UNEQUAL_ELEMENTS].include? status

          # stop execution if a single error is found (unless in verbose mode)
          break unless status == EQUIVALENT || opts[:verbose]

          # increment both counters when both nodes have been compared
          i += 1; j += 1
        end
        status
      end
    end

    ##
    # Compares two nodes of type Nokogiri::XML::Element.
    # - compares element attributes
    # - recursively compares element children
    #
    #   @param [Nokogiri::XML::Element] n1 left node element
    #   @param [Nokogiri::XML::Element] n2 right node element
    #   @param [Hash] opts user-overridden options
    #   @param [Array] differences inequivalence messages
    #   @param [Hash] childopts user-overridden options used for the child nodes
    #   @param [Bool] diffchildren use different options for the child nodes
    #   @param [int] status comparison status code (EQUIVALENT by default)
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareElementNodes(n1, n2, opts, differences, childopts = {}, diffchildren = false, status = EQUIVALENT)
      if n1.name == n2.name
        result = compareAttributeSets(n1, n2, n1.attribute_nodes, n2.attribute_nodes, opts, differences)
        return result unless result == EQUIVALENT || opts[:force_children] == true
        result = diffchildren ? compareChildren(n1.children, n2.children, childopts, differences, diffchildren) : compareChildren(n1.children, n2.children, opts, differences)
        status = result unless result == EQUIVALENT
      else
        status = UNEQUAL_ELEMENTS
        addDifference(n1, n2, n1.name, n2.name, opts, differences)
      end
      status
    end

    ##
    # Compares two nodes of type Nokogiri::XML::Text.
    #
    #   @param [Nokogiri::XML::Text] n1 left text node
    #   @param [Nokogiri::XML::Text] n2 right text node
    #   @param [Hash] opts user-overridden options
    #   @param [Array] differences inequivalence messages
    #   @param [int] status comparison status code (EQUIVALENT by default)
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareTextNodes(n1, n2, opts, differences, status = EQUIVALENT)
      return true if opts[:ignore_text_nodes]
      t1 = n1.content
      t2 = n2.content
      if opts[:collapse_whitespace]
        t1 = collapse(t1)
        t2 = collapse(t2)
      end
      unless t1 == t2
        status = UNEQUAL_TEXT_CONTENTS
        addDifference(n1.parent, n2.parent, t1, t2, opts, differences)
      end
      status
    end

    ##
    # Compares two sets of Nokogiri::XML::Element attributes.
    #
    #   @param [Nokogiri::XML::Element] n1 left node element
    #   @param [Nokogiri::XML::Element] n2 right node element
    #   @param [Array] a1_set left attribute set
    #   @param [Array] a2_set right attribute set
    #   @param [Hash] opts user-overridden options
    #   @param [Array] differences inequivalence messages
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareAttributeSets(n1, n2, a1_set, a2_set, opts, differences)
      return false unless a1_set.length == a2_set.length || opts[:verbose]
      if opts[:ignore_attr_order]
        compareSortedAttributeSets(n1, n2, a1_set, a2_set, opts, differences)
      else
        compareUnsortedAttributeSets(n1, n2, a1_set, a2_set, opts, differences)
      end
    end

    ##
    # Compares two sets of Nokogiri::XML::Node attributes by sorting them first.
    # When the attributes are sorted, only attributes of the same type are compared
    # to each other, and missing attributes can be easily detected.
    #
    #   @param [Nokogiri::XML::Element] n1 left node element
    #   @param [Nokogiri::XML::Element] n2 right node element
    #   @param [Array] a1_set left attribute set
    #   @param [Array] a2_set right attribute set
    #   @param [Hash] opts user-overridden options
    #   @param [Array] differences inequivalence messages
    #   @param [int] status comparison status code (EQUIVALENT by default)
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareSortedAttributeSets(n1, n2, a1_set, a2_set, opts, differences, status = EQUIVALENT)
      a1_set = a1_set.sort_by(&:name)
      a2_set = a2_set.sort_by(&:name)
      i = j = 0

      while i < a1_set.length || j < a2_set.length

        if a1_set[i].nil?
          result = compareAttributes(n1, n2, nil, a2_set[j], opts, differences); j += 1
        elsif a2_set[j].nil?
          result = compareAttributes(n1, n2, a1_set[i], nil, opts, differences); i += 1
        elsif a1_set[i].name < a2_set[j].name
          result = compareAttributes(n1, n2, a1_set[i], nil, opts, differences); i += 1
        elsif a1_set[i].name > a2_set[j].name
          result = compareAttributes(n1, n2, nil, a2_set[j], opts, differences); j += 1
        else
          result = compareAttributes(n1, n2, a1_set[i], a2_set[j], opts, differences); i += 1; j += 1
        end

        status = result unless result == EQUIVALENT
        break unless status == EQUIVALENT || opts[:verbose]
      end
      status
    end

    ##
    # Compares two sets of Nokogiri::XML::Element attributes without sorting them.
    # As a result attributes of different types may be compared, and even if all
    # attributes are identical in both sets, if their order is different,
    # the comparison will stop as soon two unequal attributes are found.
    #
    #   @param [Nokogiri::XML::Element] n1 left node element
    #   @param [Nokogiri::XML::Element] n2 right node element
    #   @param [Array] a1_set left attribute set
    #   @param [Array] a2_set right attribute set
    #   @param [Hash] opts user-overridden options
    #   @param [Array] differences inequivalence messages
    #   @param [int] status comparison status code (EQUIVALENT by default)
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareUnsortedAttributeSets(n1, n2, a1_set, a2_set, opts, differences, status = EQUIVALENT)
      [a1_set.length, a2_set.length].max.times do |i|
        result = compareAttributes(n1, n2, a1_set[i], a2_set[i], opts, differences)
        status = result unless result == EQUIVALENT
        break unless status == EQUIVALENT
      end
      status
    end

    ##
    # Compares two attributes by name and value.
    #
    #   @param [Nokogiri::XML::Element] n1 left node element
    #   @param [Nokogiri::XML::Element] n2 right node element
    #   @param [Nokogiri::XML::Attr] a1 left attribute
    #   @param [Nokogiri::XML::Attr] a2 right attribute
    #   @param [Hash] opts user-overridden options
    #   @param [Array] differences inequivalence messages
    #   @param [int] status comparison status code (EQUIVALENT by default)
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareAttributes(n1, n2, a1, a2, opts, differences, status = EQUIVALENT)
      if a1.nil?
        status = MISSING_ATTRIBUTE
        addDifference(n1, n2, nil, "#{a2.name}=\"#{a2.value}\"", opts, differences)
      elsif a2.nil?
        status = MISSING_ATTRIBUTE
        addDifference(n1, n2, "#{a1.name}=\"#{a1.value}\"", nil, opts, differences)
      elsif a1.name == a2.name
        return status if attrNameExcluded?(a1.name, a2.name, opts)
        return status if attrsExcluded?(a1, a2, opts)
        return status if attrContentExcluded?(a1, a2, opts)
        if a1.value != a2.value
          status = UNEQUAL_ATTRIBUTES
          addDifference(n1, n2, "#{a1.name}=\"#{a1.value}\"", "#{a2.name}=\"#{a2.value}\"", opts, differences)
        end
      else
        status = UNEQUAL_ATTRIBUTES
        addDifference(n1, n2, "#{a1.name}=\"#{a1.value}\"", "#{a2.name}=\"#{a2.value}\"", opts, differences)
      end
      status
    end

    ##
    # Determines if a node should be excluded from the comparison. When a node is excluded,
    # it is completely ignored, as if it did not exist.
    #
    # Several types of nodes are considered ignored:
    # - comments (only in +ignore_comments+ mode)
    # - text nodes (only in +ignore_text_nodes+ mode OR when a text node is empty)
    # - node matches a user-specified css rule from +ignore_nodes+
    #
    #   @param [Nokogiri::XML::Node] n node being tested for exclusion
    #   @param [Hash] opts user-overridden options
    #
    #   @return true if excluded, false otherwise
    #
    def nodeExcluded?(n, opts)
      return true if n.is_a?(Nokogiri::XML::DTD)
      return true if n.is_a?(Nokogiri::XML::Comment) && opts[:ignore_comments]
      return true if n.is_a?(Nokogiri::XML::Text) && (opts[:ignore_text_nodes] || collapse(n.content).empty?)
      opts[:ignore_nodes].each { |css| return true if n.parent.css(css).include? n }
      false
    end

    ##
    # Checks whether two given attributes should be excluded, based on a user-specified css rule.
    # If true, only the specified attributes are ignored; all remaining attributes are still compared.
    # The CSS rule is used to locate the node that contains the attributes to be excluded.
    # The CSS rule MUST contain the name of the attribute to be ignored.
    #
    #   @param [Nokogiri::XML::Attr] a1 left attribute
    #   @param [Nokogiri::XML::Attr] a2 right attribute
    #   @param [Hash] opts user-overridden options
    #
    #   @return true if excluded, false otherwise
    #
    def attrsExcluded?(a1, a2, opts)
      opts[:ignore_attrs].each do |css|
        if css.include?(a1.name) && css.include?(a2.name)
          return true if a1.parent.xpath('../*').css(css).include?(a1.parent) && a2.parent.xpath('../*').css(css).include?(a2.parent)
        end
      end
      false
    end

    ##
    # Checks whether two given attributes should be excluded, based on their content.
    # Checks whether both attributes contain content that should be excluded, and
    # returns true only if an excluded string is contained in both attribute values.
    #
    #   @param [Nokogiri::XML::Attr] a1 left attribute
    #   @param [Nokogiri::XML::Attr] a2 right attribute
    #   @param [Hash] opts user-overridden options
    #
    #   @return true if excluded, false otherwise
    #
    def attrContentExcluded?(a1, a2, opts)
      a1_excluded = false
      a2_excluded = false
      opts[:ignore_attr_content].each do |content|
        a1_excluded ||= a1.value.include?(content)
        a2_excluded ||= a2.value.include?(content)
        return true if a1_excluded && a2_excluded
      end
      false
    end

    ##
    # Checks whether two given attributes should be excluded, based on their content.
    # Checks whether both attributes contain content that should be excluded, and
    # returns true only if an excluded string is contained in both attribute values.
    #
    #   @param [Nokogiri::XML::Attr] a1 left attribute
    #   @param [Nokogiri::XML::Attr] a2 right attribute
    #   @param [Hash] opts user-overridden options
    #
    #   @return true if excluded, false otherwise
    #
    def attrNameExcluded?(a1, a2, opts)
      a1_excluded = false
      a2_excluded = false
      opts[:ignore_attrs_by_name].each do |name|
        a1_excluded ||= a1.to_s.include?(name)
        a2_excluded ||= a2.to_s.include?(name)
        return true if a1_excluded && a2_excluded
      end
      false
    end

    ##
    # Strips the whitespace (from beginning and end) and collapses it,
    # i.e. multiple spaces, new lines and tabs are all collapsed to a single space.
    #
    #   @param [Nokogiri::XML::Node] node1 left node
    #   @param [Nokogiri::XML::Node] node2 right node
    #   @param [String] diff1 left diffing value
    #   @param [String] diff2 right diffing value
    #   @param [Hash] opts user-overridden options
    #   @param [Array] differences inequivalence messages
    #
    #   @return collapsed string
    #
    def addDifference(node1, node2, diff1, diff2, opts, differences)
      differences << { node1: node1, node2: node2, diff1: diff1, diff2: diff2 } if opts[:verbose]
    end

    ##
    # Strips the whitespace (from beginning and end) and collapses it,
    # i.e. multiple spaces, new lines and tabs are all collapsed to a single space.
    #
    #   @param [String] text string to collapse
    #
    #   @return collapsed string
    #
    def collapse(text)
      text = text.to_s unless text.is_a? String
      text.strip.gsub(/\s+/, ' ')
    end
  end
end
