require 'open-uri'


doc=Nokogiri::HTML(open('http://www.google.com/search?q=wdangmail@yahoo.com'))

doc.css('div.sb_ph').map {|item| puts item.text}
