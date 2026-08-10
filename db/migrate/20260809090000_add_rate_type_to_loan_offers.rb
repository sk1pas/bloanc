class AddRateTypeToLoanOffers < ActiveRecord::Migration[8.1]
  def change
    add_column :loan_offers, :rate_type, :integer, null: false, default: 0
    add_column :loan_offers, :fixed_rate_percent, :decimal, precision: 6, scale: 3
    add_column :loan_offers, :fixed_rate_years, :integer

    add_index :loan_offers, :rate_type
  end
end
