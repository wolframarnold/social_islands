source 'https://rubygems.org'

gem 'rails', '3.2.3'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'



# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'bootstrap-sass', '~> 2.0.2'
  gem 'bootswatch-rails', '~> 0.0.11'
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platform => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails', '~> 2.0.2'
gem 'mongo_mapper', '~> 0.11.1'
gem 'bson_ext', '~> 1.6.2'
gem 'haml', '~> 3.1.4'
gem 'haml-rails', '~> 0.3.4'
#gem 'flutie', '~> 1.3.3'
#gem 'bourbon', '~> 1.4.0'
gem 'omniauth', '~> 1.1.0'
gem 'omniauth-facebook', '~> 1.2.0'
gem 'koala', '~> 1.4.1'
gem 'resque', '~> 1.20.0'
gem 'thin', '~> 1.3.1'
gem 'newrelic_rpm', '~> 3.3.4'
gem 'eshq', '~> 0.0.4'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

group :test, :development do
  gem 'rspec-rails', '~> 2.9.0'
  gem 'database_cleaner', '~> 0.7.2'
  gem 'spork', '~> 0.9.0'
  gem 'factory_girl_rails', '~> 3.1.0', require: false
end

group :production do
  gem 'unicorn', '~> 4.3.0'
end