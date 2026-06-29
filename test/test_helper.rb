$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'compare-xml'
require 'compare-xml/version'

require 'minitest/autorun'

module ParseHelpers
  def frag(html)
    Nokogiri::HTML.fragment(html)
  end

  def doc(html)
    Nokogiri::HTML(html)
  end
end
