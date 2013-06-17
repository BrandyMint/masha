class RenamePivotalPersionToPivotalPerson < ActiveRecord::Migration
  def change
    rename_column :users, :pivotal_persion_id, :pivotal_person_id
  end
end
