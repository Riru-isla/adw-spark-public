require "rails_helper"

RSpec.describe "Api::Items", type: :request do
  let(:collection) { create(:collection) }
  let(:test_image) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/test_image.png"), "image/png") }

  describe "GET /api/collections/:collection_id/items" do
    it "returns empty array when no items" do
      get "/api/collections/#{collection.id}/items"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns items with photo URLs for the collection" do
      item = create(:item, collection: collection, name: "Rare Card")

      get "/api/collections/#{collection.id}/items"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to eq("Rare Card")
      expect(json.first["photos"]).to be_an(Array)
    end

    it "returns 404 for nonexistent collection" do
      get "/api/collections/999999/items"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/items/:id" do
    it "returns item with all fields and photos array" do
      item = create(:item, collection: collection, name: "Stamp", estimated_value: 15.0, notes: "old")

      get "/api/items/#{item.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(item.id)
      expect(json["collection_id"]).to eq(collection.id)
      expect(json["name"]).to eq("Stamp")
      expect(json["estimated_value"]).to eq(15.0)
      expect(json["notes"]).to eq("old")
      expect(json["photos"]).to be_an(Array)
    end

    it "returns 404 for nonexistent item" do
      get "/api/items/999999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/collections/:collection_id/items" do
    it "creates item with valid params → 201 with item JSON" do
      post "/api/collections/#{collection.id}/items", params: {
        name: "Coin", condition: "mint", estimated_value: 100.0, notes: "Gold coin"
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("Coin")
      expect(json["condition"]).to eq("mint")
      expect(json["collection_id"]).to eq(collection.id)
      expect(json["photos"]).to eq([])
    end

    it "creates item with photo(s) attached → response includes photo URLs" do
      post "/api/collections/#{collection.id}/items", params: {
        name: "Photo Item", condition: "good", photos: [ test_image ]
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["photos"].length).to eq(1)
      expect(json["photos"].first["url"]).to be_present
      expect(json["photos"].first["filename"]).to eq("test_image.png")
      expect(json["photos"].first["content_type"]).to eq("image/png")
    end

    it "returns 422 with invalid params (missing name)" do
      post "/api/collections/#{collection.id}/items", params: {
        condition: "mint"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end

    it "returns 422 with invalid params (missing condition)" do
      post "/api/collections/#{collection.id}/items", params: {
        name: "No Condition Item"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end
  end

  describe "PUT /api/items/:id" do
    let(:item) { create(:item, collection: collection, name: "Old Name") }

    it "updates item fields → 200" do
      put "/api/items/#{item.id}", params: { name: "New Name", condition: "mint" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("New Name")
      expect(json["condition"]).to eq("mint")
    end

    it "adds new photos → response includes all photos" do
      put "/api/items/#{item.id}", params: { name: item.name, condition: item.condition, photos: [ test_image ] }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["photos"].length).to eq(1)
      expect(json["photos"].first["filename"]).to eq("test_image.png")
    end

    it "removes photos by id via remove_photo_ids → photo no longer present" do
      item.photos.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")), filename: "test_image.png", content_type: "image/png")
      blob_id = item.photos.first.blob_id

      put "/api/items/#{item.id}", params: { name: item.name, condition: item.condition, remove_photo_ids: [ blob_id ] }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["photos"]).to eq([])
    end

    it "returns 422 with invalid params" do
      put "/api/items/#{item.id}", params: { name: "" }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end
  end

  describe "GET /api/items/search" do
    let(:collection2) { create(:collection) }
    let!(:item_alpha) { create(:item, collection: collection, name: "Alpha Card", notes: "shiny foil", condition: :mint, estimated_value: 50.0) }
    let!(:item_beta)  { create(:item, collection: collection, name: "Beta Coin", notes: nil, condition: :good, estimated_value: 10.0) }
    let!(:item_gamma) { create(:item, collection: collection2, name: "Gamma Stamp", notes: "rare find", condition: :poor, estimated_value: 5.0) }

    it "returns all items when no params given" do
      get "/api/items/search"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
    end

    it "filters by query matching name" do
      get "/api/items/search", params: { query: "alpha" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to eq("Alpha Card")
    end

    it "filters by query matching notes" do
      get "/api/items/search", params: { query: "shiny" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to eq("Alpha Card")
    end

    it "is case-insensitive for query" do
      get "/api/items/search", params: { query: "GAMMA" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to eq("Gamma Stamp")
    end

    it "filters by collection_id" do
      get "/api/items/search", params: { collection_id: collection2.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to eq("Gamma Stamp")
    end

    it "filters by condition" do
      get "/api/items/search", params: { condition: "mint" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to eq("Alpha Card")
    end

    it "filters by value_min" do
      get "/api/items/search", params: { value_min: "20" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to eq("Alpha Card")
    end

    it "filters by value_max" do
      get "/api/items/search", params: { value_max: "9" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to eq("Gamma Stamp")
    end

    it "combines multiple filters" do
      get "/api/items/search", params: { query: "a", condition: "good" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to eq("Beta Coin")
    end

    it "returns empty array when nothing matches" do
      get "/api/items/search", params: { query: "zzznomatch" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to eq([])
    end

    it "each result includes photos array" do
      get "/api/items/search"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      json.each do |item|
        expect(item["photos"]).to be_an(Array)
      end
    end
  end

  describe "DELETE /api/items/:id" do
    it "destroys item → 204" do
      item = create(:item, collection: collection)

      expect {
        delete "/api/items/#{item.id}"
      }.to change(Item, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for nonexistent item" do
      delete "/api/items/999999"

      expect(response).to have_http_status(:not_found)
    end
  end
end
