module Api
  module V1
    class BaseController < ActionController::Base
      protect_from_forgery with: :null_session
    end
  end
end
