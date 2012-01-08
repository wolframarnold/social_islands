module LinkedIn
  class Mash < ::Hashie::Mash

    # LinkedIn returns Arrays as a hash with keys :all and :total
    # and the value of the :all key is then the array
    # there is one level of indirection that makes sense for API's to
    # reduce the amount of data transferred when only the total is requested
    # but it's an awkward idiom to deal with them storing these in Mongo
    # or generally manipulating them as Ruby arrays.
    # This code turns the hash 

    def convert_value_with_normalizing_arrays(val, duping=false)
      if val.is_a?(Hash) &&
         val.length == 2 &&
         val.has_key?('values') && val.has_key?('_total')
      then
        val = val['values']
      end
      convert_value_without_normalizing_arrays val, duping
    end

    alias_method_chain :convert_value, :normalizing_arrays

  end
end
