class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :name, null: false

      t.timestamps
    end
    add_index :tags, %i[user_id name], unique: true

    create_table :taggings do |t|
      t.references :talk, null: false, foreign_key: true, index: false
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
    add_index :taggings, %i[talk_id tag_id], unique: true
  end
end
