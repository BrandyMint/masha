class CreateInvites < ActiveRecord::Migration
  def change
    create_table :invites do |t|
      t.references :user,    index: true
      t.string :email,       null: false
      t.string :role,        null: false
      t.references :project, index: true

      t.timestamps
    end
    add_index :invites, :email, :unique => true
  end
end
