module ActiveModel

  class Errors

    # Monkey-patch to Rails's errors.
    # For some reason presence validation adds attributes to errors with
    # empty messages--not sure why--and they confuse the output on the API
    # They seem to be pruned when converted to human readable messages.

    def as_json(options=nil)
      to_hash.reject { |attr, msgs| msgs.blank? }
    end

  end
end