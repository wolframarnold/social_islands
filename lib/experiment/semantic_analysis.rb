conn = Faraday.new(:url => 'http://djangocc.herokuapp.com') do |faraday|
  faraday.request  :url_encoded             # form-encode POST params
  faraday.response :logger                  # log requests to STDOUT
  faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
end

msgs.map do |text|
  text=text.scan(/[a-zA-Z '0-9]/).join
  #text=msgs[0].gsub( /\n/m, " ")
  text.gsub!(/ /, "%20")
  #response = conn.get '/alert/'+text
  response = conn.get '/sentiment/'+text
  puts response.body
  puts " "
end
