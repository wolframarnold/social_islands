#Note: This MUST BE REMOVED if you're using Devise's omniauthable, or Devise will report "invalid credentials" when attempting to log in via Twitter

Rails.application.config.middleware.use OmniAuth::Builder do
  #provider :twitter, 'j26y8PRBxAPuM8xnBBrqAQ', 'trJvHL4te7X2exFRsfs2c6juZNwBKj2RTbDhVuZFYw' # order: Consumer Key, Consumer Secret
  ## option: :force_login => true will force a new login into the Provider, even though the Provider may have previously been logged in, from a different browser tab.
  #
  #provider :facebook, '257240837631794', '700c38006358f9a7e499811cff813444'

  provider :linkedin,'zsgsnz2ig4i7', '1tqv4Nuv3H4RrvnW'
end
