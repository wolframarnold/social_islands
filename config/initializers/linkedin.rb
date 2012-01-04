require 'linkedin'

LinkedIn.configure do |config|
   config.token = 'zsgsnz2ig4i7'
   config.secret = '1tqv4Nuv3H4RrvnW'
   config.default_profile_fields = %w(first-name last-name headline location num-recommenders)
end
