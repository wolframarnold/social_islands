class Query
  extend ActiveModel::Naming

  attr_accessor :name, :uid, :user_id
  attr_reader :errors

  def initialize(attrs={})
    @valid = true
    attrs = attrs.with_indifferent_access
    %w(name uid user_id).each do |attr|
      send("#{attr}=", attrs[attr])
    end
  end

  def run_on(klass)
    key = %w(name uid user_id).find {|attr| send(attr).present?}
    @valid = key.present?
    res = nil
    if valid?
      case key
        when 'name'
          res = klass.where(name: /#{name}/i).all
        when 'user_id'
          res = klass.where(_id: user_id)
        else
          res = klass.where(key => send(key)).all
      end
      @errors = "Error: Query with #{key} = #{send(key)} did not return any results" if res.blank?
    else
      @errors = 'Error: Query must not be blank'
    end
    res
  end

  def valid?
    @valid
  end

  def persisted?
    false
  end

  def to_key
    nil
  end

  def to_param
    nil
  end
end