class Admin::WiborSnapshotsController < Admin::BaseController
  def index
    @latest_snapshot = WiborSnapshot.latest
    @snapshots = WiborSnapshot.recent.limit(30)
  end

  def refresh
    result = Wibor::Fetcher.new.call
    redirect_to admin_wibor_snapshots_path,
                notice: t("admin.wibor.flash.refreshed", date: I18n.l(result.snapshot.effective_date))
  rescue Wibor::Fetcher::FetchError => e
    redirect_to admin_wibor_snapshots_path,
                alert: t("admin.wibor.flash.refresh_failed", error: e.message)
  end
end
