class CreateExternalResources < ActiveRecord::Migration[5.0]
  def change
    create_table :external_resources do |t|
      t.string :external_id
      t.text :message
      t.string :thread_id
      t.datetime :created_at
      t.string :line_timestamp
      t.string :author_id
      t.boolean :allow_channelback, default: false

      t.timestamps
    end
    add_index :external_resources, :external_id
    add_index :external_resources, :thread_id
    add_index :external_resources, :author_id
  end
end
