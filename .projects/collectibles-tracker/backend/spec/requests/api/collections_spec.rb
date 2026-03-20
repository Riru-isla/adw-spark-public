require "rails_helper"

RSpec.describe "Api::Collections", type: :request do
  describe "GET /api/collections" do
    it "returns all collections with item_count and total_value" do
      collection = create(:collection)
      create(:item, collection: collection, estimated_value: 10.0)
      create(:item, collection: collection, estimated_value: 20.0)

      get "/api/collections"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["item_count"]).to eq(2)
      expect(json.first["total_value"]).to eq(30.0)
    end

    it "returns empty array when no collections" do
      get "/api/collections"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end
  end

  describe "GET /api/collections/:id" do
    it "returns the collection with aggregates" do
      collection = create(:collection)
      create(:item, collection: collection, estimated_value: 50.0)

      get "/api/collections/#{collection.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(collection.id)
      expect(json["item_count"]).to eq(1)
      expect(json["total_value"]).to eq(50.0)
    end

    it "returns value_by_condition with correct sums per condition" do
      collection = create(:collection)
      create(:item, collection: collection, condition: :mint, estimated_value: 100.0)
      create(:item, collection: collection, condition: :mint, estimated_value: 50.0)
      create(:item, collection: collection, condition: :good, estimated_value: 25.0)
      create(:item, collection: collection, condition: :fair, estimated_value: nil)

      get "/api/collections/#{collection.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      vbc = json["value_by_condition"]
      expect(vbc).to be_a(Hash)
      expect(vbc["mint"]).to eq(150.0)
      expect(vbc["near_mint"]).to eq(0.0)
      expect(vbc["good"]).to eq(25.0)
      expect(vbc["fair"]).to eq(0.0)
      expect(vbc["poor"]).to eq(0.0)
    end

    it "returns 404 for unknown collection" do
      get "/api/collections/999999"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/collections" do
    it "creates a collection with valid params and returns 201" do
      post "/api/collections", params: { collection: { name: "My Stamps", category: "stamps", description: "Rare stamps" } }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("My Stamps")
      expect(json["item_count"]).to eq(0)
      expect(json["total_value"]).to eq(0.0)
    end

    it "returns 422 with errors on invalid params (missing name)" do
      post "/api/collections", params: { collection: { name: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end
  end

  describe "PUT /api/collections/:id" do
    it "updates with valid params and returns 200" do
      collection = create(:collection, name: "Old Name")

      put "/api/collections/#{collection.id}", params: { collection: { name: "New Name" } }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("New Name")
    end

    it "returns 422 with errors on invalid params" do
      collection = create(:collection)

      put "/api/collections/#{collection.id}", params: { collection: { name: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end
  end

  describe "DELETE /api/collections/:id" do
    it "returns 204 and destroys the record and its items" do
      collection = create(:collection)
      create(:item, collection: collection)
      create(:item, collection: collection)

      expect {
        delete "/api/collections/#{collection.id}"
      }.to change(Collection, :count).by(-1).and change(Item, :count).by(-2)

      expect(response).to have_http_status(:no_content)
    end
  end
end
