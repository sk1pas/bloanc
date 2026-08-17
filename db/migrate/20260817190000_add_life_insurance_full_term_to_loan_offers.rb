class AddLifeInsuranceFullTermToLoanOffers < ActiveRecord::Migration[8.1]
  def change
    add_column :loan_offers, :life_insurance_full_term, :boolean, default: false, null: false
  end
end
