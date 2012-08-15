#Note: This MUST BE REMOVED if you're using Devise's omniauthable, or Devise will report "invalid credentials" when attempting to log in via Twitter

Rails.application.config.middleware.use OmniAuth::Builder do
  #provider :twitter, 'j26y8PRBxAPuM8xnBBrqAQ', 'trJvHL4te7X2exFRsfs2c6juZNwBKj2RTbDhVuZFYw' # order: Consumer Key, Consumer Secret
  ## option: :force_login => true will force a new login into the Provider, even though the Provider may have previously been logged in, from a different browser tab.
  #

  fb_perms = %w[user_about_me
                user_birthday
                user_education_history
                user_events
                user_groups
                user_hometown
                user_interests
                user_likes
                user_location
                user_notes
                user_photos
                user_questions
                user_relationships
                user_relationship_details
                user_religion_politics
                user_status
                user_videos
                user_website
                user_work_history
                email
                read_stream]

  # Removed permissions, per Whit.li drop-off is significant when asking for friends' data
  #  friends_likes
  #  friends_hometown
  #  friends_location
  #  friends_about_me
  #  friends_status
  #  friends_relationships
  #  friends_interests
  #  friends_religion_politics
  #  friends_birthday
  #  friends_hometown
  #  friends_website
  #  friends_work_history
  #  friends_education_history


  # Use Heroku-configured APP ID and SECRET for production (pointing to Social Islands)
  # or use Social Islands Dev app locally. This matters for redirect URL.
  FB_APP_ID      = Rails.env.production? ? ENV['FACEBOOK_APP_ID'] : '398796910145811'
  FB_APP_SECRET  = Rails.env.production? ? ENV['FACEBOOK_SECRET'] : '71e24820b766e844985e9ff92e1ba119'

  # See https://developers.facebook.com/docs/reference/api/permissions/ for a list of scopes
  provider :facebook, FB_APP_ID, FB_APP_SECRET, scope: fb_perms.join(',')

end
