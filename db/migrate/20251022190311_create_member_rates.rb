class CreateMemberRates < ActiveRecord::Migration[8.0]
  def change
    create_table :member_rates do |t|
      t.references :project, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.decimal :hourly_rate, precision: 10, scale: 2
      t.string :currency, limit: 3, default: 'RUB'
      t.timestamps

      t.index %i[project_id user_id], unique: true
    end
  end
end
