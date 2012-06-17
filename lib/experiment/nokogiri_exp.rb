require 'open-uri'
require 'json'

doc=Nokogiri::HTML(open('http://www.google.com/search?q=wdangmail@yahoo.com'))

doc.css('div.sb_ph').map {|item| puts item.text}



res=open('http://where.yahooapis.com/geocode?q=San_Francisco&flags=T')

xmlres=Nokogiri::HTML(res)
xmlres=Nokogiri::HTML(open('http://where.yahooapis.com/geocode?q=San_Francisco&flags=T'))
xmlres.xpath("//timezone").text


xmlres=Nokogiri::HTML(open('http://www.earthtools.org/timezone-1.1/40.71417/-74.00639'))
xmlres.xpath("//offset").text

