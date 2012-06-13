require 'csv'
require 'geoip'
require 'iconv'
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

end