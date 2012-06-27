module LoginHelpers

  extend ActiveSupport::Concern

  included do
    before do
      controller.class_eval do
        public :signed_in?, :current_facebook_profile
      end
    end
  end

end