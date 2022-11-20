require 'test_helper'

class XmlTest < Minitest::Test
  def setup
    @doc1 = Nokogiri::HTML(open('test/files/1.html'))
    @doc2 = Nokogiri::HTML(open('test/files/2.html'))
  end

  def test_that_compare_xml_completes_without_errors
    assert CompareXML.equivalent?(@doc1, @doc2, {verbose: true})
  end
end
