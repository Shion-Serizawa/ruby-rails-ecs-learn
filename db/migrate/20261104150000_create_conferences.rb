class CreateConferences < ActiveRecord::Migration[8.1]
  def change
    create_table :conferences do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :venue
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.string :website_url
      t.integer :talks_count, null: false, default: 0

      t.timestamps
    end
    add_index :conferences, %i[user_id starts_on]
  end
end
