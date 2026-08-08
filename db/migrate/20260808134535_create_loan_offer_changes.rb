class CreateLoanOfferChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :loan_offer_changes, if_not_exists: true do |t|
      t.references :loan_offer, null: false, foreign_key: true
      t.datetime :changed_at, null: false
      t.jsonb :snapshot, null: false, default: {}
      t.string :note

      t.timestamps
    end

    add_index :loan_offer_changes, :changed_at, if_not_exists: true
  end
end
