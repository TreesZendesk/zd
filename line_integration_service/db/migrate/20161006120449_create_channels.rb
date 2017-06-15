class CreateChannels < ActiveRecord::Migration[5.0]
  def change
    create_table :channels do |t|
      t.string :name
      t.string :channel_id
      t.string :channel_secret
      t.string :channel_access_token
      t.string :zendesk_subdomain
      t.string :zendesk_locale

      t.string :instance_push_id
      t.string :zendesk_access_token
    end
    add_index :channels, :channel_id
  end
end
