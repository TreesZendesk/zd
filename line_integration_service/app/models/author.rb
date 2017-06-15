class Author < ApplicationRecord
  validates :author_id, uniqueness: true
  has_many :external_resources, primary_key: 'author_id'
end
