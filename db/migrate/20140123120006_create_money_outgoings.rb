class CreateMoneyOutgoings < ActiveRecord::Migration
  def change
    create_table :money_outgoings do |t|
      t.references :company, null: false
      t.references :user, null: false
      t.decimal :amount, null: false
      t.integer :implementer_id, null: false
      t.references :project
      t.date :date, null: false
      t.text :description

      t.timestamps
    end

    add_index :money_outgoings, [:project_id, :date]
    add_index :money_outgoings, [:date]
    add_index :money_outgoings, [:implementer_id]
    add_index :money_outgoings, :user_id
  end
end
