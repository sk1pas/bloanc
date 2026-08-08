class Admin::BanksController < Admin::BaseController
  before_action :set_bank, only: %i[show edit update destroy]

  def index
    @banks = Bank.alphabetical.includes(logo_attachment: :blob)
  end

  def show
    @loan_offers = @bank.loan_offers.ordered
  end

  def new
    @bank = Bank.new
  end

  def edit
  end

  def create
    @bank = Bank.new(bank_params)

    if @bank.save
      redirect_to admin_bank_path(@bank), notice: t("admin.banks.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    purge_logo_if_requested

    if @bank.update(bank_params)
      redirect_to admin_bank_path(@bank), notice: t("admin.banks.flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bank.destroy
    redirect_to admin_banks_path, notice: t("admin.banks.flash.destroyed")
  end

  private

  def set_bank
    @bank = Bank.find(params[:id])
  end

  def purge_logo_if_requested
    return unless ActiveModel::Type::Boolean.new.cast(params.dig(:bank, :remove_logo))
    return unless @bank.logo.attached?

    @bank.logo.purge
  end

  def bank_params
    params.require(:bank).permit(:title, :description, :website_url, :logo)
  end
end
