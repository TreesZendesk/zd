class ExternalResource < ApplicationRecord
  validates :external_id, uniqueness: true
  has_one :job
  belongs_to :author, primary_key: 'author_id'
end
