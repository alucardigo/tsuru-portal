class NotificationsController < ApplicationController
  def index
    @notifications = current_user.notifications_received
                                 .includes(:demand)
                                 .recent
                                 .limit(50)
    @unread_count = current_user.notifications_received.unread.count
  end

  def mark_read
    notification = current_user.notifications_received.find(params[:id])
    notification.mark_read!
    if notification.demand
      redirect_to demand_path(notification.demand)
    else
      redirect_to notifications_path
    end
  end

  def mark_all_read
    current_user.notifications_received.unread.update_all(read_at: Time.current)
    redirect_to notifications_path, notice: "Todas as notificações marcadas como lidas."
  end
end
