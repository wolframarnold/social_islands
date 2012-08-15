source 'https://rubygems.org'

# Tell Heroku to use Ruby 1.9.3; Heroku's default on Cedar is 1.9.2
ruby '1.9.3'  # if this line causes an error, upgrade the bundler gem with:  gem install bundler

gem 'rails', '3.2.6'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'



# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.5'
  gem 'coffee-rails', '~> 3.2.2'
  gem 'bootstrap-sass', '~> 2.0.4.0'
  gem 'bootswatch-rails', '~> 0.0.12'
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platform => :ruby

  gem 'uglifier', '~> 1.2.6'
end

gem 'jquery-rails', '~> 2.0.2'
gem 'mongoid', '~> 2.4.12'
gem 'bson_ext', '~> 1.6.2'
gem 'haml', '~> 3.1.6'
gem 'haml-rails', '~> 0.3.4'
gem 'omniauth', '~> 1.1.0'
gem 'omniauth-facebook', '~> 1.3.0'
#gem 'koala', '~> 1.5.0'
gem 'koala', git: 'git://github.com/wolframarnold/koala.git', branch: 'issue237_batch_block_gets_processed_result', ref: '80b3545e44174bb4f24235c15f9c22727fe7f562'
gem 'resque', '~> 1.20.0'
gem 'thin', '~> 1.4.1'
gem 'newrelic_rpm', '~> 3.4.0.1'
gem 'eshq', '~> 0.0.4'
gem 'simple_form', '~> 2.0.2'
gem 'will_paginate_mongoid', '~> 1.0.5'
gem 'bootstrap-will_paginate', '~> 0.0.7'
gem 'geocoder', '~> 1.1.2'
gem 'gmaps4rails', '~> 1.5.2'
gem 'mongoid_rails_migrations', git: 'https://github.com/adacosta/mongoid_rails_migrations.git', ref: '3994d38f26de305271e5c73cb459b3f68aad38cc'
gem 'fb-channel-file', '~> 0.0.1'  # for FB Channel file, see: http://stackoverflow.com/questions/8336878/how-to-write-a-channel-html-file-in-rails-for-facebook and https://developers.facebook.com/docs/reference/javascript/

gem '3scale_client', '~> 2.2.10'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
gem 'jbuilder', '~> 0.4.0'

gem 'rest-client', '~> 1.6.7'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

group :test, :development do
  gem 'rspec-rails', '~> 2.11.0'
  gem 'heroku'
  gem 'highline', '~> 1.6.12'
end

group :test do
  # Don't put this in the development group, because it disables all net connections by default !!!
  gem 'database_cleaner', '~> 0.8.0'
  gem 'spork', '~> 0.9.2'
  gem 'factory_girl_rails', '~> 3.5.0', require: false
  gem 'webmock', '~> 1.8.7'
  gem 'vcr', '~> 2.2.2'
end

group :production do
  gem 'unicorn', '~> 4.3.0'
end
