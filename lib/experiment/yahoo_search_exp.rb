require 'csv'
require Rails.root.join("app/models/api-helpers/yahoo_boss_search")

module YahooSearch

  class EmailCheck
    include Mongoid::Document
    field :email,         type: String
    field :search_engine, type: String
    field :search_return, type: Hash

    def count
      return search_return["bossresponse"]["web"]["count"].to_i
    end
  end

  #email=("wdyangmail@yahoo.com")

  def pull_email_check_from_yahoo
    csv_text = File.read('crowdspringwithIP.csv',  encoding: "ISO8859-1")
    @csv = CSV.parse(csv_text, :headers => true)

    #(2090..(@csv.length-1)).map do |i1|
    (213).map do |i1|
      email = @csv[i1]["Buyer email"]
      doc=YahooBossSearch.run_search(email)
      record = EmailCheck.create(email: email)
      record.search_return = doc
      record.search_engine = "YahooBoss"
      record.save!
      puts i1.to_s+"  "+email+" returns "+doc["bossresponse"]["web"]["count"]
    end
  end

  def collect_email_stats
    csv_text = File.read('crowdspringwithIP.csv',  encoding: "ISO8859-1")
    @csv = CSV.parse(csv_text, :headers => true)

    email_stat=Hash.new()

    (212..(@csv.length-1)).map do |i1|
      email = @csv[i1]["Buyer email"]
      doc=EmailCheck.where(email:email)[-1].search_return
      count=doc["bossresponse"]["web"]["count"]
      email_stat[email]=count
      puts i1.to_s+"  "+email+" returns "+count
    end

    num_unique_email=email_stat.length
    num_returned = 0
    num_no_return=0
    email_stat.map do |stat|
      if stat[1].to_i > 0
        num_returned = num_returned+1
      else
        num_no_return=num_no_return+1
      end
    end
    puts "returned: "+ num_returned.to_s + ", no return: "+ num_no_return.to_s+" from total: "+num_unique_email.to_s

    #find a sample of no return emails
    email_stat.map do |stat|
      if stat[1].to_i == 0
        puts stat[0]
      end
    end
  end

  def put_email_check_to_csv
    csv_text = File.read('crowdspringFullIP.csv',  encoding: "ISO8859-1")
    @csvCS = CSV.parse(csv_text, :headers => true)

    (0..(@csvCS.length-1)).map do |i1|
      email = @csvCS[i1]["Buyer email"]
      email_check = EmailCheck.where(email:email).last
      @csvCS[i1]["Yahoo Count"]=email_check.count.to_s
      puts i1.to_s + " "+ email_check.count.to_s
    end

    CSV.open("CS_checked_w_IP_Email.csv", "wb",  encoding: "ISO8859-1") do |csvFile|
    csvFile << @csvCS.headers
    i1=0
    @csvCS.each do |c|
      puts i1
      csvFile<< c
      i1=i1+1
    end
  end


end