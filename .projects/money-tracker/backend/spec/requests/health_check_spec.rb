require 'rails_helper'

RSpec.describe "Health Check", type: :request do
  describe "GET /up" do
    it "returns 200" do
      get "/up"
      expect(response).to have_http_status(200)
    end
  end
end
