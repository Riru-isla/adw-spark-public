class CreateBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :budgets do |t|
      t.references :category, null: false, foreign_key: true
      t.integer :month, null: false
      t.integer :year, null: false
      t.decimal :limit_amount, precision: 10, scale: 2, null: false

      t.timestamps
    end
    add_index :budgets, [:category_id, :month, :year], unique: true
  end
end
