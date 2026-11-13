require 'test_helper'

class ProcessingInstructionsTest < Minitest::Test
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
