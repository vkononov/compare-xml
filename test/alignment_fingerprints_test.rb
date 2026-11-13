require 'test_helper'

class AlignmentFingerprintsTest < Minitest::Test
  def test_alignment_does_not_confuse_attribute_values_with_attribute_boundaries
    left = Nokogiri::XML('<r><e a="1 b=2"/></r>')
    right = Nokogiri::XML('<r><e a="1" b="2"/></r>')

    refute_empty CompareXML.equivalent?(left, right, verbose: true, align_children: true)
  end
end
