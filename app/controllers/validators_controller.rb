class ValidatorsController < ApplicationController
  skip_forgery_protection only: :linus  # XHR rate-limited by Rack::Attack

  def linus
    text = params[:text].to_s
    require_quantitative = params[:require_quantitative].to_s != "false"

    result = Validators::LinusRedaction.call(text: text, require_quantitative: require_quantitative)

    render json: {
      ok: result.success?,
      violations: result.errors || [],
      reason: result.reason
    }
  end
end
