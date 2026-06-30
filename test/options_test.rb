require 'test_helper'

class OptionsTest < Minitest::Test
  include ParseHelpers

  def test_collapse_whitespace
    a = frag('<a href="/x">   SOME    TEXT   </a>')
    b = frag('<a href="/x"> SOME TEXT </a>')

    assert CompareXML.equivalent?(a, b)
    refute CompareXML.equivalent?(a, b, { collapse_whitespace: false })
  end

  def test_ignore_attr_order
    a = frag('<a href="/admin" class="button" target="_blank">L</a>')
    b = frag('<a class="button" target="_blank" href="/admin">L</a>')

    assert CompareXML.equivalent?(a, b)
    refute CompareXML.equivalent?(a, b, { ignore_attr_order: false })
  end

  def test_ignore_attr_content
    a = frag('<a href="/admin" id="button_1" class="blue button">L</a>')
    b = frag('<a href="/admin" id="button_2" class="info button">L</a>')

    refute CompareXML.equivalent?(a, b)
    assert CompareXML.equivalent?(a, b, { ignore_attr_content: ['button'] })
  end

  def test_ignore_attrs_by_css
    a = frag('<div><a href="/admin" target="_blank">L</a></div>')
    b = frag('<div><a href="/admin" target="_self">L</a></div>')

    refute CompareXML.equivalent?(a, b)
    assert CompareXML.equivalent?(a, b, { ignore_attrs: ['a[target]'] })
  end

  def test_ignore_attrs_by_name
    a = frag('<a href="/admin" target="_blank">L</a>')
    b = frag('<a href="/admin" target="_self">L</a>')

    refute CompareXML.equivalent?(a, b)
    assert CompareXML.equivalent?(a, b, { ignore_attrs_by_name: ['target'] })
  end

  def test_ignore_attrs_by_name_when_attribute_missing_on_one_side
    a = frag('<div class="foo"></div>')
    b = frag('<div></div>')

    refute CompareXML.equivalent?(a, b)
    assert CompareXML.equivalent?(a, b, { ignore_attrs_by_name: ['class'] })
  end

  def test_ignore_attrs_by_css_when_attribute_missing_on_one_side
    a = frag('<div><a href="/admin" target="_blank">L</a></div>')
    b = frag('<div><a href="/admin">L</a></div>')

    refute CompareXML.equivalent?(a, b)
    assert CompareXML.equivalent?(a, b, { ignore_attrs: ['a[target]'] })
  end

  def test_ignore_attr_content_when_attribute_present_on_one_side_only
    a = frag('<a id="button_1">L</a>')
    b = frag('<a>L</a>')

    refute CompareXML.equivalent?(a, b)
    assert CompareXML.equivalent?(a, b, { ignore_attr_content: ['button'] })
  end

  def test_ignore_comments
    a = frag('<div><!-- one -->Link</div>')
    b = frag('<div><!-- two -->Link</div>')

    assert CompareXML.equivalent?(a, b)
    refute CompareXML.equivalent?(a, b, { ignore_comments: false })
  end

  def test_ignore_nodes_by_css
    a = frag('<div><a href="/admin" target="_blank">L1</a></div>')
    b = frag('<div><a href="/index" target="_self">L2</a></div>')

    refute CompareXML.equivalent?(a, b)
    assert CompareXML.equivalent?(a, b, { ignore_nodes: ['a[target]'] })
  end

  def test_ignore_text_nodes
    a = frag('<a href="/admin">SOME TEXT</a>')
    b = frag('<a href="/admin">DIFFERENT TEXT</a>')

    refute CompareXML.equivalent?(a, b)
    assert CompareXML.equivalent?(a, b, { ignore_text_nodes: true })
  end

  def test_verbose_difference_structure
    a = doc('<html><head><title>TITLE</title></head><body><h1>HEADING</h1></body></html>')
    b = doc('<html><head><title>OTHER</title></head><body><h1 id="main">HEADING</h1></body></html>')
    differences = CompareXML.equivalent?(a, b, { verbose: true })

    assert_equal 2, differences.length
    text_diff = differences.find { |d| d[:diff1] == 'TITLE' }

    assert_equal 'OTHER', text_diff[:diff2]
    attr_diff = differences.find { |d| d[:diff2] == 'id="main"' }

    assert_nil attr_diff[:diff1]
  end

  def test_force_children_compares_children_despite_parent_difference
    a = doc('<html><body><div class="a"><p>X</p></div></body></html>')
    b = doc('<html><body><div class="b"><p>Y</p></div></body></html>')

    assert_equal 1, CompareXML.equivalent?(a, b, { verbose: true }).length
    assert_equal 2, CompareXML.equivalent?(a, b, { verbose: true, force_children: true }).length
  end

  def test_force_children_still_reports_attribute_difference_when_children_match
    a = frag('<div class="a"><p>X</p></div>')
    b = frag('<div class="b"><p>X</p></div>')

    refute CompareXML.equivalent?(a, b, { force_children: true })
    assert CompareXML.equivalent?(a, frag('<div class="a"><p>X</p></div>'), { force_children: true })
  end

  def test_ignore_children
    a = frag('<div><a href="/a">L1</a></div>')
    b = frag('<div><a href="/b">L2</a></div>')

    refute CompareXML.equivalent?(a, b)
    assert CompareXML.equivalent?(a, b, { ignore_children: true })
  end

  def test_diff_children_uses_separate_options_for_children
    a = doc('<html><body><p>Hello</p></body></html>')
    b = doc('<html><body><p>Goodbye</p></body></html>')

    refute CompareXML.equivalent?(a, b)
    assert CompareXML.equivalent?(a, b, {}, { ignore_text_nodes: true }, true)
  end
end
