class ApiClient

  THREE_SCALE_APPLICATION_FIND_URL = 'https://trustcc-admin.3scale.net/admin/api/applications/find.xml'

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,            type: String
  field :app_id,         type: String
  field :postback_domain, type: String

  index :app_id, unique: true
  index :name

  attr_accessible :name, :postback_domain

  validates :name, :app_id, presence: true

  def self.setup_if_missing!(app_id)
    api_client = ApiClient.where(app_id: app_id).first
    if api_client.nil?
      api_client = ApiClient.new
      api_client.app_id = app_id
      api_client.fetch_api_manager_application_record
      api_client.save!
    end
    api_client
  end

  def update_from_api_manager
    fetch_api_manager_application_record
    save
  end

  def fetch_api_manager_application_record
    return if Rails.env.development?  # Don't go to 3Scale in dev mode
    conn=Faraday.new(THREE_SCALE_APPLICATION_FIND_URL) do |builder|
      builder.request :url_encoded
      builder.adapter :net_http
    end

    response = conn.get do |req|
      req.params['provider_key'] = ThreeScale.client.provider_key
      req.params['app_id'] = app_id
    end

    if response.status.to_i == 200
      doc = Nokogiri::XML(response.body)
      self.name = doc.at_css('application>name').text.strip
      if pb_node = doc.at_css('application > extra_fields > postback_domain')
        self.postback_domain = pb_node.text.strip
      end
    else
      Rails.logger.tagged('3Scale Application Find, APP ID', app_id) { Rails.logger.info("Search failed, status: #{response.status}, #{response.inspect}") }
    end
  end

end