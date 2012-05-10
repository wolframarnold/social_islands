require 'heroku/command/base'

module HerokuUtils

  def self.get_mongo_production_credentials

    heroku_base = Heroku::Command::BaseWithApp.new
    config_vars = heroku_base.heroku.config_vars(heroku_base.app)

    # We're after:
    #"MONGOHQ_URL"=>"mongodb://username:password@host:port/db_name"

    mongohq_url = config_vars['MONGOHQ_URL']
    parse_mongo_uri(mongohq_url)
  end

  def self.parse_mongo_uri(mongo_uri)
    proto_user_pw, host_port_db = mongo_uri.split('@')
    username, password = proto_user_pw.sub('mongodb://', '').split(':')
    host_port, db = host_port_db.split('/')

    {host_port_db: host_port_db,
     host_port: host_port,
     db: db,
     username: username, password: password}
  end

end