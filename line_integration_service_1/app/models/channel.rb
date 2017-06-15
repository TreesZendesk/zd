class Channel < ActiveRecord::Base
  validates :channel_id, uniqueness: true
  validates :zendesk_subdomain, uniqueness: true

  def valid_request? request
  end
end
