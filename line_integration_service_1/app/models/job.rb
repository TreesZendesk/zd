class Job < ApplicationRecord
  belongs_to :external_resource

  STATUS = ['new', 'processing', 'done']
end
