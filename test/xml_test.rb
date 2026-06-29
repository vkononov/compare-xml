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
end
