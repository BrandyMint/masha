class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.references :owner, null: false
      t.string :name, null: false
      t.decimal :balance, null: false, default: 0

      t.timestamps
    end

    add_index :companies, [:owner_id, :name], unique: true
  end
end
