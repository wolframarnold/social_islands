namespace :mongohq do

  def prod_mongo
    @prod_mongo ||= HerokuUtils.get_mongo_production_credentials
  end

  def local_mongo
    return @local_mongo unless @local_mongo.nil?
    mongo_config = File.expand_path('../../../config/mongoid.yml', __FILE__)
    dev_db_uri = YAML.load_file(mongo_config)['development']['uri']
    raise "No 'uri' entry found for development environment in confog/mongoid.yml" if dev_db_uri.blank?
    @local_mongo = HerokuUtils.parse_mongo_uri(dev_db_uri)
  end

  def common_mongo_dump_restore_args(mongo_config)
    args = "-h #{mongo_config[:host_port]} "
    args << "-u #{mongo_config[:username]} " unless mongo_config[:username].blank?
    args << "-p #{mongo_config[:password]} " unless mongo_config[:password].blank?
    args << "-d #{mongo_config[:db]} "
  end

  def mongo_dump(tmp_dir, mongo_config)
    cmd = "mongodump "
    cmd << common_mongo_dump_restore_args(mongo_config)
    cmd << "-v " # verbose
    cmd << "-o #{tmp_dir}"

    puts cmd
    # mongodump -h staff.mongohq.com:10018 -u heroku -p <password> -d <db> -o tmp/mongo_dump
    system(cmd)
  end

  def mongo_restore(tmp_dir, mongo_config, source_db_name)
    cmd = "mongorestore "
    cmd << common_mongo_dump_restore_args(mongo_config)
    cmd << "--drop "
    cmd << "-v " # verbose
    cmd << tmp_dir.join(source_db_name).to_s

    puts cmd
    # mongorestore -h 127.0.0.1 -d trust_exchange_development --drop -v tmp/mongo_dump/<db_name>/
    system cmd
  end

  desc "Pull production data from Heroku into local database"
  task :pull do
    require 'highline'
    require File.expand_path('../../heroku_utils', __FILE__)

    hl = HighLine.new
    agreed = hl.agree("WARNING!!! This operation will **DESTROY** your local database. Do you want to proceed? (yes/no)")

    if agreed
      tmp_dir = Pathname.new(File.expand_path("../../../tmp/mongo_dump", __FILE__))

      mongo_dump(tmp_dir, prod_mongo)

      mongo_restore(tmp_dir, local_mongo, prod_mongo[:db])

      FileUtils.rm_rf tmp_dir
    end
  end

  desc "Push local development database up to Heroku's production database. THIS WILL DESTROY THE PRODUCTION DATABASE!!!"
  task :push do

    require 'highline'
    require File.expand_path('../../heroku_utils', __FILE__)

    hl = HighLine.new
    agreed = hl.ask("WARNING!!! This operation will **DESTROY** your **PRODUCTION** database.\nType 'I WANT TO DESTROY THE PRODUCTION DATABASE' to proceed.",
                    lambda {|resp|  resp == 'I WANT TO DESTROY THE PRODUCTION DATABASE' }) do |question|
      question.case = :up
    end

    if agreed
      tmp_dir = Pathname.new(File.expand_path("../../../tmp/mongo_dump", __FILE__))

      mongo_dump(tmp_dir, local_mongo)

      mongo_restore(tmp_dir, prod_mongo, local_mongo[:db])

      FileUtils.rm_rf tmp_dir
    end

  end

end