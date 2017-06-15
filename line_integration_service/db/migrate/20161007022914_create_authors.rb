class CreateAuthors < ActiveRecord::Migration[5.0]
  def change
    create_table :authors do |t|
      t.string :author_id
      t.string :name
      t.string :image_url

      t.timestamps
    end
    add_index :authors, :author_id
  end
end
