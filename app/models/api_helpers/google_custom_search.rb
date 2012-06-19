module GoogleCustomSearch

  # Docs:
  # https://developers.google.com/custom-search/v1/using_rest
  # Custom Search Engine Dashboard/Configuration:
  # http://www.google.com/cse/panel/basics?cx=014778836108162739641:lhdxb0t373q&sig=__ZSYcf3Uk2_kYW9LkyKxGq9DIUPU=

  GOOGLE_WEB_SEARCH_URL = 'https://www.googleapis.com/customsearch/v1'

  GOOGLE_API_KEY = 'AIzaSyBQjkzZv_uYWzOUs5kkuc_vBILiEWFxAvE'
  GOOGLE_CUSTOM_SEARCH_ENGINE_ID = '014778836108162739641:lhdxb0t373q'


  # Will return results of the following format:
  # > res.keys
  # => ["kind", "url", "queries", "context", "searchInformation", "items"]
  # > res['kind']
  # => "customsearch#search"
  # > res['url']
  # => {"type"=>"application/json", "template"=>"https://www.googleapis.com/customsearch/v1?q={searchTerms}&num={count?}&start={startIndex?}&lr={language?}&safe={safe?}&cx={cx?}&cref={cref?}&sort={sort?}&filter={filter?}&gl={gl?}&cr={cr?}&googlehost={googleHost?}&c2coff={disableCnTwTranslation?}&hq={hq?}&hl={hl?}&siteSearch={siteSearch?}&siteSearchFilter={siteSearchFilter?}&exactTerms={exactTerms?}&excludeTerms={excludeTerms?}&linkSite={linkSite?}&orTerms={orTerms?}&relatedSite={relatedSite?}&dateRestrict={dateRestrict?}&lowRange={lowRange?}&highRange={highRange?}&searchType={searchType}&fileType={fileType?}&rights={rights?}&imgSize={imgSize?}&imgType={imgType?}&imgColorType={imgColorType?}&imgDominantColor={imgDominantColor?}&alt=json"}
  # > res['queries']
  # => {"request"=>[{"title"=>"Google Custom Search - wolfram@arnold.name", "totalResults"=>"3", "searchTerms"=>"wolfram@arnold.name", "count"=>3, "startIndex"=>1, "inputEncoding"=>"utf8", "outputEncoding"=>"utf8", "safe"=>"off", "cx"=>"014778836108162739641:lhdxb0t373q", "exactTerms"=>"wolfram@arnold.name"}]}
  # > res['context']
  # => {"title"=>"Email Verification"}
  # > res['searchInformation']
  # => {"searchTime"=>0.026289, "formattedSearchTime"=>"0.03", "totalResults"=>"3", "formattedTotalResults"=>"3"}
  # > res['items'].first.keys
  # => ["kind", "title", "htmlTitle", "link", "displayLink", "snippet", "htmlSnippet", "cacheId", "formattedUrl", "htmlFormattedUrl", "pagemap"]

  def self.run_search(search_term, optional_search_params={})

    conn=Faraday.new(GOOGLE_WEB_SEARCH_URL) do |builder|
      builder.request :url_encoded
      builder.adapter :net_http
    end

    resp = conn.get do |req|
      req.params['key'] = GOOGLE_API_KEY
      req.params['cx']  = GOOGLE_CUSTOM_SEARCH_ENGINE_ID
      req.params['q']   = search_term
      req.params['exactTerms'] = search_term
      req.params.merge! optional_search_params
    end

    if resp.status.to_i == 200
      JSON.parse(resp.body)
    else
      Rails.logger.tagged('GoogleSearch', search_term) { Rails.logger.info("Search failed, status: #{resp.status}, #{resp.inspect}")}
      nil
    end

    #client = Google::APIClient.new
    #search = client.discovered_api('customsearch')
    #response = client.execute(search.cse.list, 'q' => '"search_term"', 'cx'=> GOOGLE_CUSTOM_SEARCH_ENGINE_ID)
    #status, headers, body = response
    #if status.to_i == 200
    #  body
    #else
    #  status
    #end
    #
  end

end