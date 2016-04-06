require 'compare-xml/version'
require 'nokogiri'

module CompareXML

  # default options used by the module; all of these can be overridden
  DEFAULTS_OPTS = {
      # when true, attribute order is not important (all attributes are sorted before comparison)
      # when false, attributes are compared in order and comparison stops on the first mismatch
      ignore_attr_order: true,

      # contains an array of user-specified CSS rules used to perform attribute exclusions
      # for this to work, a CSS rule MUST contain the attribute to be excluded,
      # i.e. a[href] will exclude all "href" attributes contained in <a> tags.
      ignore_attrs: {},

      # when true ignores XML and HTML comments
      # when false, all comments are compared to their counterparts
      ignore_comments: true,

      # contains an array of user-specified CSS rules used to perform node exclusions
      ignore_nodes: {},

      # when true, ignores all text nodes (although blank text nodes are always ignored)
      # when false, all text nodes are compared to their counterparts (except the empty ones)
      ignore_text_nodes: false,

      # when true, trims and collapses whitespace in text nodes and comments to a single space
      # when false, all whitespace is preserved as it is without any changes
      collapse_whitespace: true,

      # when true, provides a list of all error messages encountered in comparisons
      # when false, execution stops when the first error is encountered with no error messages
      verbose: false
  }

  # used internally only in order to differentiate equivalence for inequivalence
  EQUIVALENT = 1

  # a list of all possible inequivalence types for nodes
  # these are returned in the errors array to differentiate error types.
  MISSING_ATTRIBUTE = 2       # attribute is missing its counterpart
  MISSING_NODE = 3            # node is missing its counterpart
  UNEQUAL_ATTRIBUTES = 4      # attributes are not equal
  UNEQUAL_COMMENTS = 5        # comment contents are not equal
  UNEQUAL_DOCUMENTS = 6       # document types are not equal
  UNEQUAL_ELEMENTS = 7        # nodes have the same type but are not equal
  UNEQUAL_NODES_TYPES = 8     # nodes do not have the same type
  UNEQUAL_TEXT_CONTENTS = 9   # text contents are not equal


  class << self

    ##
    # Determines whether two XML documents or fragments are equal to each other.
    # The two parameters could be any type of XML documents, or fragments
    # or node sets or even text nodes - any subclass of Nokogiri::XML::Node.
    #
    #   @param [Nokogiri::XML::Node] n1 left attribute
    #   @param [Nokogiri::XML::Node] n2 right attribute
    #   @param [Hash] opts user-overridden options
    #
    #   @return true if equal, [Array] errors otherwise
    #
    def equivalent?(n1, n2, opts = {})
      opts, errors = DEFAULTS_OPTS.merge(opts), []
      result = compareNodes(n1, n2, opts, errors)
      opts[:verbose] ? errors : result == EQUIVALENT
    end


    private

    ##
    # Compares two nodes for equivalence. The nodes could be any subclass
    # of Nokogiri::XML::Node including node sets and document fragments.
    #
    #   @param [Nokogiri::XML::Node] n1 left attribute
    #   @param [Nokogiri::XML::Node] n2 right attribute
    #   @param [Hash] opts user-overridden options
    #   @param [Array] errors inequivalence messages
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareNodes(n1, n2, opts, errors, status = EQUIVALENT)
      if n1.class == n2.class
        case n1
          when Nokogiri::XML::Comment
            compareCommentNodes(n1, n2, opts, errors)
          when Nokogiri::HTML::Document
            compareDocumentNodes(n1, n2, opts, errors)
          when Nokogiri::XML::Element
            status = compareElementNodes(n1, n2, opts, errors)
          when Nokogiri::XML::Text
            status = compareTextNodes(n1, n2, opts, errors)
          else
            status = compareChildren(n1.children, n2.children, opts, errors)
        end
      elsif n1.nil?
        status = MISSING_NODE
        errors << [nodePath(n2), nil, status, n2.name, nodePath(n2)] if opts[:verbose]
      elsif n2.nil?
        status = MISSING_NODE
        errors << [nodePath(n1), n1.name, status, nil, nodePath(n1)] if opts[:verbose]
      else
        status = UNEQUAL_NODES_TYPES
        errors << [nodePath(n1), n1.class, status, n2.class, nodePath(n2)] if opts[:verbose]
      end
      status
    end


    ##
    # Compares two nodes of type Nokogiri::HTML::Comment.
    #
    #   @param [Nokogiri::XML::Comment] n1 left attribute
    #   @param [Nokogiri::XML::Comment] n2 right attribute
    #   @param [Hash] opts user-overridden options
    #   @param [Array] errors inequivalence messages
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareCommentNodes(n1, n2, opts, errors, status = EQUIVALENT)
      return true if opts[:ignore_comments]
      t1, t2 = n1.content, n2.content
      t1, t2 = collapse(t1), collapse(t2) if opts[:collapse_whitespace]
      unless t1 == t2
        status = UNEQUAL_COMMENTS
        errors << [nodePath(n1.parent), t1, status, t2, nodePath(n2.parent)] if opts[:verbose]
      end
      status
    end


    ##
    # Compares two nodes of type Nokogiri::HTML::Document.
    #
    #   @param [Nokogiri::XML::Document] n1 left attribute
    #   @param [Nokogiri::XML::Document] n2 right attribute
    #   @param [Hash] opts user-overridden options
    #   @param [Array] errors inequivalence messages
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareDocumentNodes(n1, n2, opts, errors, status = EQUIVALENT)
      if n1.name == n2.name
        status = compareChildren(n1.children, n2.children, opts, errors)
      else
        status == UNEQUAL_DOCUMENTS
        errors << [nodePath(n1), n1, status, n2, nodePath(n2)] if opts[:verbose]
      end
      status
    end


    ##
    # Compares two sets of Nokogiri::XML::NodeSet elements.
    #
    #   @param [Nokogiri::XML::NodeSet] n1_set left set of Nokogiri::XML::Node elements
    #   @param [Nokogiri::XML::NodeSet] n2_set right set of Nokogiri::XML::Node elements
    #   @param [Hash] opts user-overridden options
    #   @param [Array] errors inequivalence messages
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareChildren(n1_set, n2_set, opts, errors, status = EQUIVALENT)
      i = 0; j = 0
      while i < n1_set.length || j < n2_set.length
        if !n1_set[i].nil? && nodeExcluded?(n1_set[i], opts)
          i += 1 # increment counter if left node is excluded
        elsif !n2_set[j].nil? && nodeExcluded?(n2_set[j], opts)
          j += 1 # increment counter if right node is excluded
        else
          result = compareNodes(n1_set[i], n2_set[j], opts, errors)
          status = result unless result == EQUIVALENT

          # return false so that this subtree could halt comparison on error
          # but neighbours of parents' subtrees could still be compared (in verbose mode)
          return false if status == UNEQUAL_NODES_TYPES || status == UNEQUAL_ELEMENTS

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
    #   @param [Nokogiri::XML::Element] n1 left attribute
    #   @param [Nokogiri::XML::Element] n2 right attribute
    #   @param [Hash] opts user-overridden options
    #   @param [Array] errors inequivalence messages
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareElementNodes(n1, n2, opts, errors, status = EQUIVALENT)
      if n1.name == n2.name
        result = compareAttributeSets(n1.attribute_nodes, n2.attribute_nodes, opts, errors)
        status = result unless result == EQUIVALENT
        result = compareChildren(n1.children, n2.children, opts, errors)
        status = result unless result == EQUIVALENT
      else
        status = UNEQUAL_ELEMENTS
        errors << [nodePath(n1), n1.name, status, n2.name, nodePath(n2)] if opts[:verbose]
      end
      status
    end


    ##
    # Compares two nodes of type Nokogiri::XML::Text.
    #
    #   @param [Nokogiri::XML::Text] n1 left attribute
    #   @param [Nokogiri::XML::Text] n2 right attribute
    #   @param [Hash] opts user-overridden options
    #   @param [Array] errors inequivalence messages
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareTextNodes(n1, n2, opts, errors, status = EQUIVALENT)
      return true if opts[:ignore_text_nodes]
      t1, t2 = n1.content, n2.content
      t1, t2 = collapse(t1), collapse(t2) if opts[:collapse_whitespace]
      unless t1 == t2
        status = UNEQUAL_TEXT_CONTENTS
        errors << [nodePath(n1.parent), t1, status, t2, nodePath(n2.parent)] if opts[:verbose]
      end
      status
    end


    ##
    # Compares two sets of Nokogiri::XML::Node attributes.
    #
    #   @param [Array] a1_set left attribute set
    #   @param [Array] a2_set right attribute set
    #   @param [Hash] opts user-overridden options
    #   @param [Array] errors inequivalence messages
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareAttributeSets(a1_set, a2_set, opts, errors)
      return false unless a1_set.length == a2_set.length || opts[:verbose]
      if opts[:ignore_attr_order]
        compareSortedAttributeSets(a1_set, a2_set, opts, errors)
      else
        compareUnsortedAttributeSets(a1_set, a2_set, opts, errors)
      end
    end


    ##
    # Compares two sets of Nokogiri::XML::Node attributes by sorting them first.
    # When the attributes are sorted, only attributes of the same type are compared
    # to each other, and missing attributes can be easily detected.
    #
    #   @param [Array] a1_set left attribute set
    #   @param [Array] a2_set right attribute set
    #   @param [Hash] opts user-overridden options
    #   @param [Array] errors inequivalence messages
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareSortedAttributeSets(a1_set, a2_set, opts, errors, status = EQUIVALENT)
      a1_set, a2_set = a1_set.sort_by { |a| a.name }, a2_set.sort_by { |a| a.name }
      i = j = 0

      while i < a1_set.length || j < a2_set.length
        if a1_set[i].nil?
          result = compareAttributes(nil, a2_set[j], opts, errors); j += 1
        elsif a2_set[j].nil?
          result = compareAttributes(a1_set[i], nil, opts, errors); i += 1
        elsif a1_set[i].name < a2_set[j].name
          result = compareAttributes(a1_set[i], nil, opts, errors); i += 1
        elsif a1_set[i].name > a2_set[j].name
          result = compareAttributes(nil, a2_set[j], opts, errors); j += 1
        else
          result = compareAttributes(a1_set[i], a2_set[j], opts, errors); i += 1; j += 1
        end
        status = result unless result == EQUIVALENT
        break unless status == EQUIVALENT || opts[:verbose]
      end
      status
    end


    ##
    # Compares two sets of Nokogiri::XML::Node attributes without sorting them.
    # As a result attributes of different types may be compared, and even if all
    # attributes are identical in both sets, if their order is different,
    # the comparison will stop as soon two unequal attributes are found.
    #
    #   @param [Array] a1_set left attribute set
    #   @param [Array] a2_set right attribute set
    #   @param [Hash] opts user-overridden options
    #   @param [Array] errors inequivalence messages
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareUnsortedAttributeSets(a1_set, a2_set, opts, errors, status = EQUIVALENT)
      [a1_set.length, a2_set.length].max.times do |i|
        result = compareAttributes(a1_set[i], a2_set[i], opts, errors)
        status = result unless result == EQUIVALENT
        break unless status == EQUIVALENT
      end
      status
    end


    ##
    # Compares two attributes by name and value.
    #
    #   @param [Nokogiri::XML::Attr] a1 left attribute
    #   @param [Nokogiri::XML::Attr] a2 right attribute
    #   @param [Hash] opts user-overridden options
    #   @param [Array] errors inequivalence messages
    #
    #   @return type of equivalence (from equivalence constants)
    #
    def compareAttributes(a1, a2, opts, errors, status = EQUIVALENT)
      if a1.nil?
        status = MISSING_ATTRIBUTE
        errors << [nodePath(a2.parent), nil, status, "#{a2.name}=\"#{a2.value}\"", nodePath(a2.parent)] if opts[:verbose]
      elsif a2.nil?
        status = MISSING_ATTRIBUTE
        errors << [nodePath(a1.parent), "#{a1.name}=\"#{a1.value}\"", status, nil, nodePath(a1.parent)] if opts[:verbose]
      elsif a1.name == a2.name
        return status if attrsExcluded?(a1, a2, opts)
        if a1.value != a2.value
          status = UNEQUAL_ATTRIBUTES
          errors << [nodePath(a1.parent), "#{a1.name}=\"#{a1.value}\"", status, "#{a2.name}=\"#{a2.value}\"", nodePath(a2.parent)] if opts[:verbose]
        end
      else
        status = UNEQUAL_ATTRIBUTES
        errors << [nodePath(a1.parent), a1.name, status, a2.name, nodePath(a2.parent)] if opts[:verbose]
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
    # - node matches a user-specified css rule from +ignore_comments+
    #
    #   @param [Nokogiri::XML::Node] n node being tested for exclusion
    #   @param [Hash] opts user-overridden options
    #
    #   @return true if excluded, false otherwise
    #
    def nodeExcluded?(n, opts)
      return true if n.is_a?(Nokogiri::XML::Comment) && opts[:ignore_comments]
      return true if n.is_a?(Nokogiri::XML::Text) && (opts[:ignore_text_nodes] || collapse(n.content).empty?)
      opts[:ignore_nodes].each do |css|
        return true if n.xpath('../*').css(css).include?(n)
      end
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
    # Produces the hierarchical ancestral path of a node in the following format: <html:body:div(3):h2:b(2)>.
    # This means that the element is located in:
    #
    #   <html>
    #     <body>
    #       <div>...</div>
    #       <div>...</div>
    #       <div>
    #         <h2>
    #           <b>...</b>
    #           <b>TARGET</b>
    #         </h2>
    #       </div>
    #     </body>
    #   </html>
    #
    # Note that the counts of element locations only apply to elements of the same type. For example, div(3) means
    # that it is the 3rd <div> element in the <body>, but there could be many other elements in between the three
    # <div> elements.
    #
    # When +ignore_comments+ mode is disabled, mismatching comments will show up as <...:comment>.
    #
    #   @param [Nokogiri::XML::Node] n node for which to determine a hierarchical path
    #
    #   @return true if excluded, false otherwise
    #
    def nodePath(n)
      name = n.name

      # find the index of the node if there are several of the same type
      siblings = n.xpath("../#{name}")
      name += "(#{siblings.index(n) + 1})" if siblings.length > 1

      if defined? n.parent
        status = "#{nodePath(n.parent)}:#{name}"
        status = status[1..-1] if status[0] == ':'
        status
      end
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