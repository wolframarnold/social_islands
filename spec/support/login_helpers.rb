module LoginHelpers

  extend ActiveSupport::Concern

  included do
    before do
      controller.class_eval do
        public :signed_in?, :current_user
      end
    end
  end

end