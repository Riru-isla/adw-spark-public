class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :name, null: false
      t.integer :condition, null: false
      t.decimal :estimated_value, precision: 10, scale: 2
      t.date :acquisition_date
      t.text :notes
      t.references :collection, null: false, foreign_key: true

      t.timestamps
    end
  end
end
