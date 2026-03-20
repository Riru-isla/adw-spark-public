require "rails_helper"

RSpec.describe "Integration flows", type: :request do
  let(:test_image) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/test_image.png"), "image/png") }

  describe "create collection → add item with photo → appears on dashboard" do
    it "item appears in recently_added_items with correct name, collection_name, photo, and updated totals" do
      post "/api/collections", params: { collection: { name: "Pokemon Cards", category: "Cards" } }
      expect(response).to have_http_status(:created)
      collection_id = JSON.parse(response.body)["id"]

      post "/api/collections/#{collection_id}/items", params: {
        name: "Foil Charizard",
        condition: "mint",
        estimated_value: 250.0,
        photos: [ test_image ]
      }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["photos"].length).to eq(1)

      get "/api/dashboard"
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["total_items"]).to eq(1)
      expect(json["total_estimated_value"]).to eq(250.0)

      recent_item = json["recently_added_items"].find { |i| i["name"] == "Foil Charizard" }
      expect(recent_item).to be_present
      expect(recent_item["collection_name"]).to eq("Pokemon Cards")
      expect(recent_item["photos"].length).to eq(1)
      expect(recent_item["photos"].first["url"]).to be_present
    end
  end

  describe "search by name returns only matching item" do
    it "returns only the item whose name matches the query, with photos array and collection_id" do
      collection = create(:collection)
      create(:item, collection: collection, name: "Foil Charizard", condition: "mint")
      create(:item, collection: collection, name: "Base Pikachu", condition: "good")

      get "/api/items/search", params: { query: "charizard" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to eq("Foil Charizard")
      expect(json.first["photos"]).to be_an(Array)
      expect(json.first["collection_id"]).to eq(collection.id)
    end
  end
end
