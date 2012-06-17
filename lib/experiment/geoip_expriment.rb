require 'csv'
require 'geoip'
require 'iconv'
require 'tzinfo'
require 'open-uri'

#require 'timezone'
#require 'time'
#require 'active_support'

module GeoipExperiment
  csv_text = File.read('cS-Trust.csv',  encoding: "ISO8859-1")
  @csv = CSV.parse(csv_text, :headers => true)
  #csv_text = File.read('cS-Trust.csv',  encoding: "UTF-8")
  #csv_utf8=Iconv.conv('UTF8', 'LATIN1', csv_text)
  #@csv = CSV.parse(csv_utf8, :headers => true)
  #csv_text = File.read('cS-Trust.csv',  encoding: "ISO8859-1")
  #csvutf = csv_text.unpack('C*').pack('U*')
  #@csv = CSV.parse(csv_text, :headers => true)

  #csvlatin=CSV.read("cS-Trust.csv",  encoding: "ISO8859-1")
  #csvlatin=CSV.read("cS-Trust.csv",  encoding: "utf-8")

  #@csv = CSV.parse(csvlatin, :headers => true)


  def get_time_zone(i1)
    d=@csv[i1]["Date posted"]
    tUTC=@csv[i1]["Time posted"]

    @csv[i1]["ip_country"] = ""
    @csv[i1]["ip_timezone"]=""
    @csv[i1]["ip_city"]=""
    @csv[i1]["local_time"]=""
    ip=@csv[i1]["Buyer IP Address"]
    if ip=="no_entry"
      puts i1.to_s + ", "+ip
      return
    end
    c = GeoIP.new('GeoLiteCity.dat').city(ip)
    if c.present?
      t_local = ""
      if c.timezone.present?
        timezone=c.timezone

        d1=d.split('/')
        month=d1[0]
        day=d1[1]
        year=d1[2]
        t=Time.parse(year+"/"+month+"/"+day+","+tUTC+" Z")
        #puts i1.to_s+", "+c.ip+", "+c.country_name+", "+c.city_name+", "+c.timezone
        #puts t
        t_local=t.in_time_zone(timezone)
        #puts t_local
      end
      @csv[i1]["ip_country"] = c.country_name.present? ? c.country_name : ""
      @csv[i1]["ip_timezone"]=c.timezone.present? ? c.timezone : ""
      @csv[i1]["ip_city"]=c.city_name.present? ? c.city_name.encode("utf-8") : ""
      @csv[i1]["local_time"]=t_local.present? ? t_local.hour.to_s+":"+t_local.min.to_s : ""
    else
      puts i1.to_s+" NO IP MATCHING"
    end

  end


  (0..(@csv.length-1)).map do |i1|
    puts i1
    get_time_zone(i1)
  end

  CSV.open("crowdspringwithIP.csv", "wb",  encoding: "ISO8859-1") do |csvFile|
    csvFile << @csv.headers
    i1=0
    @csv.each do |c|
      puts i1
      csvFile<< c
      i1=i1+1
    end
  end

  #getting time zone information for those didn't returned TZ'

# following code doesn't work
#  res=open("http://where.yahooapis.com/geocode?q=San_Francisco&flags=T")
#  Timezone::Configure.begin do |c|
#    c.username = 'wdyangmail'
#  end

  #getting timezone information for ips from Maxmind
  csv_text = File.read('maxminddata.csv',  encoding: "ISO8859-1")
  @csvmaxmind = CSV.parse(csv_text, :headers => true)

  OffsetHash = Hash.new
  CountryHash = Hash.new
  CityHash = Hash.new
  (0..(@csvmaxmind.length-1)).map do |i1|
    if @csvmaxmind[i1]['Latitude'].present?
      ip = @csvmaxmind[i1]['IP Address']
      lat=@csvmaxmind[i1]['Latitude']
      lon=@csvmaxmind[i1]['Longitude']
      xmlres=Nokogiri::HTML(open('http://www.earthtools.org/timezone-1.1/'+lat+'/'+lon))
      offset=xmlres.xpath("//offset").text

      OffsetHash[ip]=offset.to_i
      puts i1.to_s+": "+lat+", "+lon + "offset: "+ offset

    end
  end

  (0..(@csvmaxmind.length-1)).map do |i1|
    ip = @csvmaxmind[i1]['IP Address']
    CountryHash[ip]=@csvmaxmind[i1]["Country Name"] if @csvmaxmind[i1]["Country Name"].present?
    CityHash[ip]=@csvmaxmind[i1]["City"] if @csvmaxmind[i1]["City"].present?
  end


  #add discovered localtime through maxmind to csv
  csv_text = File.read('crowdspringwithIP.csv',  encoding: "ISO8859-1")
  @csvCS = CSV.parse(csv_text, :headers => true)

  (0..(@csvCS.length-1)).map do |i1|
    if @csvCS[i1]["local_time"].blank?
      ip=@csvCS[i1]["Buyer IP Address"]

      d=@csvCS[i1]["Date posted"]
      tUTC=@csvCS[i1]["Time posted"]
      d1=d.split('/')
      month=d1[0]
      day=d1[1]
      year=d1[2]
      t=Time.parse(year+"/"+month+"/"+day+","+tUTC+" Z")

      if OffsetHash[ip].present?
        t_local =t+OffsetHash[ip].hours
        @csvCS[i1]["local_time"]=t_local.hour.to_s+":"+t_local.min.to_s
      end
      @csvCS[i1]["ip_country"] = CountryHash[ip].present? ? CountryHash[ip] : ""
      @csvCS[i1]["ip_city"]=CityHash[ip].present? ? CityHash[ip] : ""
    end
  end

  CSV.open("crowdspringFullIP.csv", "wb",  encoding: "ISO8859-1") do |csvFile|
    csvFile << @csvCS.headers
    i1=0
    @csvCS.each do |c|
      puts i1
      csvFile<< c
      i1=i1+1
    end
  end


end