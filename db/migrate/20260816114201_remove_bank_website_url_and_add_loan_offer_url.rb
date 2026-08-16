class RemoveBankWebsiteUrlAndAddLoanOfferUrl < ActiveRecord::Migration[8.1]
  def change
    remove_column :banks, :website_url, :string

    change_column_null :loan_offers, :title, true

    change_column_default :loan_offers, :property_insurance_monthly, from: 0.0, to: nil
    change_column_null :loan_offers, :property_insurance_monthly, true

    add_column :loan_offers, :url, :string
  end
end
