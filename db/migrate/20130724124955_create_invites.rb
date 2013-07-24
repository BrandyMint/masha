class CreateInvites < ActiveRecord::Migration
  def change
    create_table :invites do |t|
      t.string :email
      t.string :role
      t.references :project, index: true
    end
  end
end
