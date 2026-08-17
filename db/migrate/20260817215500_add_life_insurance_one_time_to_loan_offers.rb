class AddLifeInsuranceOneTimeToLoanOffers < ActiveRecord::Migration[8.1]
  def change
    add_column :loan_offers, :life_insurance_one_time, :boolean, default: false, null: false
  end
end
