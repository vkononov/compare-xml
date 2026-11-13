require 'test_helper'

class RegressionTest < Minitest::Test
  def test_attribute_namespace_identity_in_both_order_modes
    left = Nokogiri::XML('<r xmlns:a="urn:a" a:x="1"/>')
    right = Nokogiri::XML('<r xmlns:b="urn:b" b:x="1"/>')
    equivalent_prefix = Nokogiri::XML('<r xmlns:b="urn:a" b:x="1"/>')
    [true, false].each do |ignore_order|
      refute CompareXML.equivalent?(left, right, ignore_attr_order: ignore_order)
      assert CompareXML.equivalent?(left, equivalent_prefix, ignore_attr_order: ignore_order)
    end
  end

  def test_alignment_does_not_confuse_attribute_values_with_attribute_boundaries
    left = Nokogiri::XML('<r><e a="1 b=2"/></r>')
    right = Nokogiri::XML('<r><e a="1" b="2"/></r>')

    refute_empty CompareXML.equivalent?(left, right, verbose: true, align_children: true)
  end

  def test_processing_instructions_compare_target_and_content
    left = Nokogiri::XML('<r><?task one?></r>')
    ['<r><?task two?></r>', '<r><?other one?></r>'].each do |xml|
      right = Nokogiri::XML(xml)

      refute CompareXML.equivalent?(left, right)
      refute_empty CompareXML.equivalent?(left, right, verbose: true, align_children: true)
    end
    assert CompareXML.equivalent?(left, left.dup)
  end
end
