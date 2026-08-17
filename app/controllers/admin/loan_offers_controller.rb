class Admin::LoanOffersController < Admin::BaseController
  before_action :set_loan_offer, only: %i[show edit update destroy]
  before_action :set_banks, only: %i[new create edit update]

  def index
    @loan_offers = LoanOffer.includes(:bank).ordered
    @wibor_snapshot = WiborSnapshot.latest
  end

  def show
    @wibor_snapshot = WiborSnapshot.latest
    @changes = @loan_offer.loan_offer_changes.recent.limit(20)
  end

  def new
    @loan_offer = LoanOffer.new(
      active: true,
      rate_type: :variable,
      wibor_kind: :wibor_3m,
      overpayment_mode: :no_overpayment,
      overpayment_coef: 1.0
    )
  end

  def edit
  end

  def create
    @loan_offer = LoanOffer.new(loan_offer_params)

    if @loan_offer.save
      redirect_to admin_loan_offer_path(@loan_offer), notice: t("admin.loan_offers.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    previous_snapshot = @loan_offer.snapshot_payload

    if @loan_offer.update(loan_offer_params)
      persist_history!(previous_snapshot) if save_history_requested?
      redirect_to admin_loan_offer_path(@loan_offer), notice: t("admin.loan_offers.flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @loan_offer.destroy
    redirect_to admin_loan_offers_path, notice: t("admin.loan_offers.flash.destroyed")
  end

  private

  def set_loan_offer
    @loan_offer = LoanOffer.find(params[:id])
  end

  def set_banks
    @banks = Bank.alphabetical
  end

  def save_history_requested?
    ActiveModel::Type::Boolean.new.cast(params[:save_history])
  end

  def persist_history!(previous_snapshot)
    @loan_offer.loan_offer_changes.create!(
      changed_at: Time.current,
      note: params[:history_note],
      snapshot: {
        previous: previous_snapshot,
        current: @loan_offer.snapshot_payload
      }
    )
  end

  def loan_offer_params
    params.require(:loan_offer).permit(
      :bank_id,
      :title,
      :url,
      :description,
      :promoted_from,
      :promoted_until,
      :rate_type,
      :fixed_rate_percent,
      :fixed_rate_years,
      :bank_margin_percent,
      :wibor_kind,
      :bank_commission_percent,
      :life_insurance_percent,
      :life_insurance_years,
      :life_insurance_full_term,
      :life_insurance_one_time,
      :life_insurance_total,
      :property_insurance_monthly,
      :overpayment_penalty_years,
      :overpayment_penalty_percent,
      :overpayment_penalty_min_amount,
      :active
    )
  end
end
