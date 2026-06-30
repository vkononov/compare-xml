require 'test_helper'

class AlignTest < Minitest::Test
  def xml(string)
    Nokogiri::XML(string)
  end

  def test_aligned_insertions_are_reported_as_additions
    left = xml('<root><a>1</a><b>2</b><c>3</c></root>')
    right = xml('<root><c>3</c></root>')

    diffs = CompareXML.equivalent?(left, right, { verbose: true, align_children: true })

    assert_equal 2, diffs.length
    assert(diffs.all? { |d| d[:node2].nil? && d[:diff2].nil? })
    assert_equal %w[a b], diffs.map { |d| d[:node1].name }.sort
  end

  def test_aligned_removals_are_reported_as_removals
    left = xml('<root><c>3</c></root>')
    right = xml('<root><a>1</a><b>2</b><c>3</c></root>')

    diffs = CompareXML.equivalent?(left, right, { verbose: true, align_children: true })

    assert_equal 2, diffs.length
    assert(diffs.all? { |d| d[:node1].nil? && d[:diff1].nil? })
    assert_equal %w[a b], diffs.map { |d| d[:node2].name }.sort
  end

  def test_aligned_in_place_edit_is_reported_as_a_change
    left = xml('<root><a>1</a><b>2</b></root>')
    right = xml('<root><a>1</a><b>99</b></root>')

    diffs = CompareXML.equivalent?(left, right, { verbose: true, align_children: true })

    assert_equal 1, diffs.length
    assert_equal %w[2 99], [diffs.first[:diff1], diffs.first[:diff2]]
    refute_nil diffs.first[:node2]
  end

  def test_aligned_identical_trees_have_no_differences
    left = xml('<root><a>1</a><b>2</b><c>3</c></root>')

    assert_empty CompareXML.equivalent?(left, left.dup, { verbose: true, align_children: true })
  end

  def test_reordered_identical_blocks_show_as_one_removal_and_one_addition
    left = xml('<root><a>1</a><b>2</b></root>')
    right = xml('<root><b>2</b><a>1</a></root>')

    diffs = CompareXML.equivalent?(left, right, { verbose: true, align_children: true })
    removals = diffs.count { |d| d[:node2].nil? }
    additions = diffs.count { |d| d[:node1].nil? }

    assert_equal 2, diffs.length
    assert_equal 1, removals
    assert_equal 1, additions
  end

  def test_without_alignment_insertions_collapse_into_a_positional_change
    left = xml('<root><a>1</a><b>2</b><c>3</c></root>')
    right = xml('<root><c>3</c></root>')

    diffs = CompareXML.equivalent?(left, right, { verbose: true })

    assert_equal 1, diffs.length
    refute_nil diffs.first[:node1]
    refute_nil diffs.first[:node2]
  end

  def test_alignment_does_not_change_boolean_result
    left = xml('<root><a>1</a><c>3</c></root>')
    right = xml('<root><c>3</c></root>')

    refute CompareXML.equivalent?(left, right, { align_children: true })
    assert CompareXML.equivalent?(left, left.dup, { align_children: true })
  end
end
