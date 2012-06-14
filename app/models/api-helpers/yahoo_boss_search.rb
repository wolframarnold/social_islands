module YahooBossSearch

  # Will return a hash with the following format:
  # {'bossresponse' => {'responsecode'=> 200, 'web' => ...}}
  # The 'web' entry contains 4 keys: "start", "count", "totalresults", "results"
  # 'start' is the starting point of the results (starts at 0), used to paginate across requests
  # 'count' is the number of returned results in this query, max. 50
  # 'totalresults' is the number of total results four for the search term
  # 'results' is an array of search results with the following sub keys: "date", "clickurl", "url", "dispurl", "title", "abstract"

  WEB_SEARCH_URL = 'http://yboss.yahooapis.com/ysearch/web'

  # our credentials -- note that each query is billed to us, cost $.80/1000 queries
  YAHOO_CONSUMER_KEY = 'dj0yJmk9Wmo3eXJZZmZsQW9EJmQ9WVdrOWJFVlJUMlp2TkdjbWNHbzlNVGcwTnpNek56WTJNZy0tJnM9Y29uc3VtZXJzZWNyZXQmeD02NA--'
  YAHOO_CONSUMER_SECRET = '4a780971ac755e1e2db3063cf9b4a582f8210010'

  # Note: This method does not batch requests together and will probably be fairly slow for many requests in sequence
  # We should probably use a higher-performing HTTP library with parallel requests and use
  # batching on the Yahoo side as well.
  def self.run_search(search_term)
    params = HashWithIndifferentAccess.new
    params[:q] = search_term

    params[:oauth_consumer_key] = YAHOO_CONSUMER_KEY
    params[:oauth_nonce] = OAuth::Helper.generate_key
    params[:oauth_signature_method] = "HMAC-SHA1"
    params[:oauth_timestamp] = OAuth::Helper.generate_timestamp
    params[:oauth_version] = "1.0"

    request = OAuth::RequestProxy.proxy({method: 'GET', uri: WEB_SEARCH_URL,
                                         parameters: params}.with_indifferent_access)

    request.sign! consumer_secret: YAHOO_CONSUMER_SECRET, token_secret: nil

    #p request.signed_uri

    conn=Faraday.new(WEB_SEARCH_URL) do |builder|
      builder.request :url_encoded
      builder.adapter :net_http
    end

    resp = conn.get request.signed_uri

    if resp.status.to_i == 200
      JSON.parse(resp.body)
    else
      resp.status
    end
  end

end