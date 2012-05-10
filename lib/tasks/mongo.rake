namespace :mongo do

  desc "Pull production data from Heroku into local database"
  task :pull do
    require 'highline'
    require File.expand_path('../../heroku_utils', __FILE__)

    hl = HighLine.new
    agreed = hl.agree("WARNING!!! This operation will **DESTROY** your local database. Do you want to proceed? (yes/no)")

    if agreed
      prod_mongo = HerokuUtils.get_mongo_production_credentials

      tmp_dir = Pathname.new(File.expand_path("../../../tmp/mongo_dump", __FILE__))

      cmd =  "mongodump "
      cmd << "-h #{prod_mongo[:host_port]} "
      cmd << "-u #{prod_mongo[:username]} "
      cmd << "-p #{prod_mongo[:password]} "
      cmd << "-d #{prod_mongo[:db]} "
      cmd << "-v "  # verbose
      cmd << "-o #{tmp_dir}"

      # puts cmd
      # mongodump -h staff.mongohq.com:10018 -u heroku -p <password> -d <db> -o tmp/mongo_dump
      system(cmd)

      mongo_config = File.expand_path('../../../config/mongoid.yml', __FILE__)
      dev_db_uri = YAML.load_file(mongo_config)['development']['uri']
      raise "No 'uri' entry found for development environment in confog/mongoid.yml" if dev_db_uri.blank?
      local_mongo = HerokuUtils.parse_mongo_uri(dev_db_uri)

      cmd =  "mongorestore "
      cmd << "-h #{local_mongo[:host_port]} "
      cmd << "-d #{local_mongo[:db]} "
      cmd << "--drop "
      cmd << "-v "  # verbose
      cmd << tmp_dir.join(prod_mongo[:db]).to_s

      # puts cmd
      # mongorestore -h 127.0.0.1 -d trust_exchange_development --drop -v tmp/mongo_dump/<db_name>/
      system cmd

      FileUtils.rm_rf tmp_dir
    end
  end

end