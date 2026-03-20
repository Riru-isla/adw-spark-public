require "rails_helper"

RSpec.describe "Api::Categories", type: :request do
  describe "GET /api/categories" do
    it "returns 200 with all categories" do
      create(:category, name: "Food")
      create(:category, name: "Transport")

      get "/api/categories"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.first.keys).to include("id", "name", "icon", "color", "created_at", "updated_at")
    end
  end

  describe "POST /api/categories" do
    context "with valid params" do
      it "returns 201 with created category" do
        post "/api/categories", params: { category: { name: "Food", color: "#FF0000", icon: "🍔" } }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["name"]).to eq("Food")
        expect(json["color"]).to eq("#FF0000")
        expect(json["icon"]).to eq("🍔")
      end
    end

    context "with invalid params (missing name)" do
      it "returns 422 with errors" do
        post "/api/categories", params: { category: { color: "#FF0000", icon: "🍔" } }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json).to have_key("errors")
      end
    end
  end

  describe "PATCH /api/categories/:id" do
    let(:category) { create(:category) }

    context "with valid params" do
      it "returns 200 with updated category" do
        patch "/api/categories/#{category.id}", params: { category: { name: "Updated Name" } }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["name"]).to eq("Updated Name")
      end
    end

    context "with invalid params" do
      it "returns 422 with errors" do
        patch "/api/categories/#{category.id}", params: { category: { name: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json).to have_key("errors")
      end
    end

    context "with unknown id" do
      it "returns 404" do
        patch "/api/categories/99999", params: { category: { name: "X" } }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/categories/:id" do
    context "when category has no transactions" do
      it "returns 204" do
        category = create(:category)

        delete "/api/categories/#{category.id}"

        expect(response).to have_http_status(:no_content)
      end
    end

    context "when category has transactions" do
      it "returns 422" do
        category = create(:category)
        create(:transaction, category: category)

        delete "/api/categories/#{category.id}"

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Cannot delete category with existing transactions")
      end
    end

    context "with unknown id" do
      it "returns 404" do
        delete "/api/categories/99999"

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
