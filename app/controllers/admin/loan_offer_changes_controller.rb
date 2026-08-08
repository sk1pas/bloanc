class Admin::LoanOfferChangesController < Admin::BaseController
  def index
    @loan_offer = LoanOffer.find(params[:loan_offer_id])
    @changes = @loan_offer.loan_offer_changes.recent
  end
end
