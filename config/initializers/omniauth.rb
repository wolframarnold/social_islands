#Note: This MUST BE REMOVED if you're using Devise's omniauthable, or Devise will report "invalid credentials" when attempting to log in via Twitter

Rails.application.config.middleware.use OmniAuth::Builder do
  #provider :twitter, 'j26y8PRBxAPuM8xnBBrqAQ', 'trJvHL4te7X2exFRsfs2c6juZNwBKj2RTbDhVuZFYw' # order: Consumer Key, Consumer Secret
  ## option: :force_login => true will force a new login into the Provider, even though the Provider may have previously been logged in, from a different browser tab.
  #
          #user_about_me
          #user_activities
          #user_birthday
          #user_checkins
          #user_education_history
          #user_events
          #user_groups
          #user_hometown
          #user_interests
          #user_likes
          #user_location
          #user_notes
          #user_photos
          #user_questions
          #user_relationships
          #user_relationship_details
          #user_religion_politics
          #user_status
          #user_videos
          #user_website
          #user_work_history
          #email
          #read_stream

          # also see:
          # friends_location permission to FQL query for friends' location

  fb_perms = %w[user_about_me
                user_activities
                user_birthday
                user_checkins
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
                friends_likes
                email
                read_stream]


  # Use Heroku-configured APP ID and SECRET for production (pointing to Social Islands)
  # or use Social Islands Dev app locally. This matters for redirect URL.
  fb_app_id      = Rails.env.production? ? ENV['FACEBOOK_APP_ID'] : '398796910145811'
  fb_app_secret  = Rails.env.production? ? ENV['FACEBOOK_SECRET'] : '71e24820b766e844985e9ff92e1ba119'

  # See https://developers.facebook.com/docs/reference/api/permissions/ for a list of scopes
  provider :facebook, fb_app_id, fb_app_secret, scope: fb_perms.join(',')

end
