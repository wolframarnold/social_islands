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
         val.keys.sort == %w(_total values) ||  # 2 keys: _total and values indicate array
         val == {'_total' => 0}  # Empty arrays are missing the 'values' key
      then
        val = val['values'] || []
      end
      convert_value_without_normalizing_arrays val, duping
    end

    alias_method_chain :convert_value, :normalizing_arrays

  end
end
