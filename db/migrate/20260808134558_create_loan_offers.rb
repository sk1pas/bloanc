class CreateLoanOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :loan_offers, if_not_exists: true do |t|
      t.references :bank, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.date :promoted_from
      t.date :promoted_until
      t.decimal :bank_margin_percent, precision: 6, scale: 3, null: false
      t.integer :wibor_kind, null: false, default: 1
      t.decimal :bank_commission_percent, precision: 6, scale: 3, null: false, default: 0
      t.decimal :life_insurance_percent, precision: 8, scale: 4
      t.integer :life_insurance_years
      t.decimal :life_insurance_total, precision: 12, scale: 2
      t.decimal :property_insurance_monthly, precision: 12, scale: 2, null: false, default: 0
      t.integer :overpayment_grace_years, null: false, default: 0
      t.integer :overpayment_mode, null: false, default: 0
      t.decimal :overpayment_coef, precision: 8, scale: 3, null: false, default: 1.0
      t.decimal :overpayment_amount, precision: 12, scale: 2, null: false, default: 0
      t.integer :overpayment_penalty_years, null: false, default: 0
      t.decimal :overpayment_penalty_percent, precision: 6, scale: 3, null: false, default: 0
      t.decimal :overpayment_penalty_min_amount, precision: 12, scale: 2, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :loan_offers, :active, if_not_exists: true
  end
end
