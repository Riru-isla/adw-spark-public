class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :date, null: false
      t.text :notes
      t.references :category, null: false, foreign_key: true
      t.string :transaction_type, null: false
      t.string :expense_kind

      t.timestamps
    end
    add_index :transactions, :date
  end
end
