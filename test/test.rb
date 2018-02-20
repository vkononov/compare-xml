require_relative '../lib/compare-xml'

doc1 = Nokogiri::HTML(open('1.html'))
doc2 = Nokogiri::HTML(open('2.html'))
puts CompareXML.equivalent?(doc1, doc2, verbose: true)
