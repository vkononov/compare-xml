require 'test_helper'

class XmlTest < Minitest::Test
  include ParseHelpers

  def setup
    @doc1 = doc(File.read('test/files/1.html'))
    @doc2 = doc(File.read('test/files/2.html'))
  end

  def test_identical_fragments_are_equivalent
    assert CompareXML.equivalent?(frag('<a href="/x">Link</a>'), frag('<a href="/x">Link</a>'))
  end

  def test_identical_multi_child_fragments_are_equivalent
    assert CompareXML.equivalent?(frag('<p>A</p><p>B</p>'), frag('<p>A</p><p>B</p>'))
  end

  def test_identical_documents_are_equivalent
    assert CompareXML.equivalent?(@doc1, @doc1.dup)
  end

  def test_fragments_with_different_text_are_not_equivalent
    refute CompareXML.equivalent?(frag('<p>A</p>'), frag('<p>B</p>'))
  end

  def test_elements_with_different_names_are_not_equivalent
    refute CompareXML.equivalent?(frag('<p>A</p>'), frag('<div>A</div>'))
  end

  def test_elements_with_extra_child_are_not_equivalent
    refute CompareXML.equivalent?(frag('<ul><li>A</li></ul>'), frag('<ul><li>A</li><li>B</li></ul>'))
  end

  def test_different_documents_are_not_equivalent
    refute CompareXML.equivalent?(@doc1, @doc2)
  end

  def test_verbose_returns_no_differences_for_identical_documents
    assert_empty CompareXML.equivalent?(@doc1, @doc1.dup, { verbose: true })
  end

  def test_verbose_reports_differences_for_different_documents
    differences = CompareXML.equivalent?(@doc1, @doc2, { verbose: true })

    refute_empty differences
    assert(differences.all? { |d| d.keys.sort == %i[diff1 diff2 node1 node2] })
  end

  def test_comparing_non_nodes_raises
    assert_raises(RuntimeError) { CompareXML.equivalent?('a', 'b') }
  end

  def test_node_sets_compare_their_members
    left = Nokogiri::XML('<r><a>1</a><b>2</b></r>').root.element_children
    right = Nokogiri::XML('<r><c>1</c><d>2</d></r>').root.element_children

    refute CompareXML.equivalent?(left, right)
    assert CompareXML.equivalent?(left, Nokogiri::XML('<r><a>1</a><b>2</b></r>').root.element_children)
  end

  def test_node_sets_of_different_sizes_report_the_missing_member
    left = Nokogiri::XML('<r><a>1</a><b>2</b></r>').root.element_children
    right = Nokogiri::XML('<r><a>1</a></r>').root.element_children
    differences = CompareXML.equivalent?(left, right, { verbose: true })

    assert_equal 1, differences.length
    assert_equal 'b', differences.first[:node1].name
    assert_nil differences.first[:node2]
  end

  def test_node_sets_honour_child_options
    left = Nokogiri::XML('<r><p>Hello</p></r>').root.element_children
    right = Nokogiri::XML('<r><p>Goodbye</p></r>').root.element_children

    refute CompareXML.equivalent?(left, right)
    assert CompareXML.equivalent?(left, right, {}, { ignore_text_nodes: true }, true)
  end

  def test_elements_in_different_namespaces_are_not_equivalent
    left = Nokogiri::XML('<r xmlns:a="urn:a"><a:item>x</a:item></r>').root
    right = Nokogiri::XML('<r xmlns:b="urn:b"><b:item>x</b:item></r>').root

    refute CompareXML.equivalent?(left, right)
    differences = CompareXML.equivalent?(left, right, { verbose: true })

    assert_equal 1, differences.length
    assert_equal ['{urn:a}item', '{urn:b}item'], differences.first.values_at(:diff1, :diff2)
  end

  def test_namespace_prefix_does_not_matter_when_the_uri_matches
    left = Nokogiri::XML('<r xmlns:a="urn:x"><a:item>x</a:item></r>').root
    right = Nokogiri::XML('<r xmlns:b="urn:x"><b:item>x</b:item></r>').root

    assert CompareXML.equivalent?(left, right)
  end

  def test_namespaced_and_unnamespaced_elements_are_not_equivalent
    left = Nokogiri::XML('<r xmlns="urn:x"><item>x</item></r>').root
    right = Nokogiri::XML('<r><item>x</item></r>').root

    refute CompareXML.equivalent?(left, right)
  end
end
