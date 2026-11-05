class CreateTalks < ActiveRecord::Migration[8.1]
  def change
    create_table :talks do |t|
      t.references :conference, null: false, foreign_key: true
      t.string :title, null: false
      t.string :speaker, null: false
      t.datetime :starts_at
      t.string :room
      t.integer :status, null: false, default: 0
      t.integer :rating
      t.text :notes
      t.boolean :favorite, null: false, default: false

      t.timestamps
    end
    add_index :talks, %i[conference_id starts_at]
    add_check_constraint :talks, "rating IS NULL OR rating BETWEEN 1 AND 5", name: "talks_rating_range"
  end
end
