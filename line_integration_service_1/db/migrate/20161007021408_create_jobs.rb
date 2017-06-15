class CreateJobs < ActiveRecord::Migration[5.0]
  def change
    create_table :jobs do |t|
      t.string :channel_id
      t.integer :external_resource_id
      t.string :status
      t.string :zendesk_status
      t.string :channel_uid
      t.string :thread_id

      t.timestamps
    end
    add_index :jobs, :channel_id
    add_index :jobs, :channel_uid
    add_index :jobs, :thread_id
  end
end
