class DemandDigestJob < ApplicationJob
  queue_as :default

  def perform
    recipients = User.where(role: %i[gestor analista_pdi])
    recipients.each do |user|
      DemandDigestMailer.weekly_summary(user).deliver_later
    end
  end
end
