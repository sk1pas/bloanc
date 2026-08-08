class Admin::DashboardController < Admin::BaseController
  def index
    @banks_count = Bank.count
    @loan_offers_count = LoanOffer.count
    @wibor_snapshot = WiborSnapshot.latest
    @latest_changes = LoanOfferChange.includes(loan_offer: :bank).recent.limit(8)
  end
end
