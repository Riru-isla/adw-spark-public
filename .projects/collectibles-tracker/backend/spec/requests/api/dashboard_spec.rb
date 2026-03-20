require "rails_helper"

RSpec.describe "Api::Dashboard", type: :request do
  let(:test_image) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/test_image.png"), "image/png") }

  describe "GET /api/dashboard" do
    context "empty state" do
      it "returns zeros and empty recently_added_items" do
        get "/api/dashboard"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["total_collections"]).to eq(0)
        expect(json["total_items"]).to eq(0)
        expect(json["total_estimated_value"]).to eq(0.0)
        expect(json["recently_added_items"]).to eq([])
      end
    end

    context "aggregate stats" do
      it "returns correct counts and sum, treating nil estimated_value as 0" do
        collection1 = create(:collection)
        collection2 = create(:collection)
        create(:item, collection: collection1, estimated_value: 10.0)
        create(:item, collection: collection1, estimated_value: 25.5)
        create(:item, collection: collection2, estimated_value: nil)

        get "/api/dashboard"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["total_collections"]).to eq(2)
        expect(json["total_items"]).to eq(3)
        expect(json["total_estimated_value"]).to eq(35.5)
      end
    end

    context "value_by_condition" do
      it "returns value_by_condition summed across all collections" do
        col1 = create(:collection)
        col2 = create(:collection)
        create(:item, collection: col1, condition: :mint, estimated_value: 200.0)
        create(:item, collection: col2, condition: :mint, estimated_value: 50.0)
        create(:item, collection: col1, condition: :near_mint, estimated_value: 30.0)
        create(:item, collection: col1, condition: :good, estimated_value: nil)

        get "/api/dashboard"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        vbc = json["value_by_condition"]
        expect(vbc).to be_a(Hash)
        expect(vbc["mint"]).to eq(250.0)
        expect(vbc["near_mint"]).to eq(30.0)
        expect(vbc["good"]).to eq(0.0)
        expect(vbc["fair"]).to eq(0.0)
        expect(vbc["poor"]).to eq(0.0)
      end
    end

    context "recently added items limit" do
      it "returns at most 10 items ordered by created_at DESC" do
        collection = create(:collection)
        items = (1..12).map do |i|
          create(:item, collection: collection, name: "Item #{i}", created_at: i.days.ago)
        end

        get "/api/dashboard"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["recently_added_items"].length).to eq(10)

        # Newest first (smallest created_at offset = most recent)
        returned_names = json["recently_added_items"].map { |i| i["name"] }
        expect(returned_names.first).to eq("Item 1")
        expect(returned_names.last).to eq("Item 10")
      end
    end

    context "photo URLs included" do
      it "includes photo URL in recently_added_items" do
        collection = create(:collection)
        item = create(:item, collection: collection, name: "Photo Item")
        item.photos.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
          filename: "test_image.png",
          content_type: "image/png"
        )

        get "/api/dashboard"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        recent_item = json["recently_added_items"].find { |i| i["name"] == "Photo Item" }
        expect(recent_item).to be_present
        expect(recent_item["photos"].length).to eq(1)
        expect(recent_item["photos"].first["url"]).to be_present
        expect(recent_item["photos"].first["filename"]).to eq("test_image.png")
        expect(recent_item["photos"].first["content_type"]).to eq("image/png")
      end
    end
  end
end
