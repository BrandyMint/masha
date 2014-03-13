class CreateMoneyIncomings < ActiveRecord::Migration
  def change
    create_table :money_incomings do |t|
      t.references :company, null: false
      t.references :user, null: false
      t.decimal :amount, null: false
      t.string :source, null: false
      t.references :project, null: false
      t.date :date, null: false
      t.text :description

      t.timestamps
    end

    add_index :money_incomings, [:project_id, :date]
    add_index :money_incomings, [:company_id, :date]
    add_index :money_incomings, :user_id
  end
end
