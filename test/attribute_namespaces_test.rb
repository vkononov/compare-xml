require 'test_helper'

class AttributeNamespacesTest < Minitest::Test
  def test_attribute_namespace_identity_in_both_order_modes # rubocop:disable Minitest/MultipleAssertions
    left = Nokogiri::XML('<r xmlns:a="urn:a" a:x="1"/>')
    right = Nokogiri::XML('<r xmlns:b="urn:b" b:x="1"/>')
    equivalent_prefix = Nokogiri::XML('<r xmlns:b="urn:a" b:x="1"/>')
    [true, false].each do |ignore_order|
      refute CompareXML.equivalent?(left, right, ignore_attr_order: ignore_order)
      assert CompareXML.equivalent?(left, equivalent_prefix, ignore_attr_order: ignore_order)
      refute_empty CompareXML.equivalent?(left, right, verbose: true, align_children: true, ignore_attr_order: ignore_order)
      assert_empty CompareXML.equivalent?(left, equivalent_prefix, verbose: true, align_children: true, ignore_attr_order: ignore_order)
    end
  end
end
