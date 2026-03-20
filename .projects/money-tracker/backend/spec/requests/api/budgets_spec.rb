require "rails_helper"

RSpec.describe "Api::Budgets", type: :request do
  describe "GET /api/budgets" do
    it "returns 200 with budgets for the queried month/year" do
      category = create(:category)
      create(:budget, category: category, month: 3, year: 2026, limit_amount: 400)

      get "/api/budgets", params: { month: 3, year: 2026 }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      expect(json.length).to eq(1)
    end

    it "includes category, limit_amount, spent_amount, remaining_amount" do
      category = create(:category)
      create(:budget, category: category, month: 3, year: 2026, limit_amount: 400)

      get "/api/budgets", params: { month: 3, year: 2026 }

      json = JSON.parse(response.body)
      budget = json.first
      expect(budget).to have_key("category")
      expect(budget).to have_key("limit_amount")
      expect(budget).to have_key("spent_amount")
      expect(budget).to have_key("remaining_amount")
      expect(budget["category"]).to include("id", "name")
    end

    it "computes spent_amount from expense transactions in that month/year" do
      category = create(:category)
      create(:budget, category: category, month: 3, year: 2026, limit_amount: 400)
      create(:transaction, category: category, transaction_type: "expense",
             amount: 100, date: "2026-03-10")
      create(:transaction, category: category, transaction_type: "expense",
             amount: 50, date: "2026-03-20")
      create(:transaction, category: category, transaction_type: "income",
             amount: 200, date: "2026-03-15")

      get "/api/budgets", params: { month: 3, year: 2026 }

      json = JSON.parse(response.body)
      budget = json.first
      expect(budget["spent_amount"].to_f).to eq(150.0)
      expect(budget["remaining_amount"].to_f).to eq(250.0)
    end

    it "excludes income transactions from spent_amount" do
      category = create(:category)
      create(:budget, category: category, month: 3, year: 2026, limit_amount: 300)
      create(:transaction, category: category, transaction_type: "income",
             amount: 500, date: "2026-03-01")

      get "/api/budgets", params: { month: 3, year: 2026 }

      json = JSON.parse(response.body)
      expect(json.first["spent_amount"].to_f).to eq(0.0)
    end

    it "defaults to current month/year when no params provided" do
      category = create(:category)
      today = Date.today
      create(:budget, category: category, month: today.month, year: today.year, limit_amount: 200)

      get "/api/budgets"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
    end

    it "does not include budgets from other months/years" do
      category = create(:category)
      create(:budget, category: category, month: 1, year: 2026, limit_amount: 100)
      create(:budget, category: category, month: 3, year: 2026, limit_amount: 200)

      get "/api/budgets", params: { month: 3, year: 2026 }

      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["month"]).to eq(3)
    end

    it "only counts transactions within the queried month/year" do
      category = create(:category)
      create(:budget, category: category, month: 3, year: 2026, limit_amount: 400)
      create(:transaction, category: category, transaction_type: "expense",
             amount: 100, date: "2026-03-15")
      create(:transaction, category: category, transaction_type: "expense",
             amount: 999, date: "2026-02-28")

      get "/api/budgets", params: { month: 3, year: 2026 }

      json = JSON.parse(response.body)
      expect(json.first["spent_amount"].to_f).to eq(100.0)
    end
  end

  describe "POST /api/budgets" do
    context "with valid params" do
      it "returns 201 and the created budget" do
        category = create(:category)

        post "/api/budgets", params: {
          budget: { category_id: category.id, month: 3, year: 2026, limit_amount: 500 }
        }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["limit_amount"].to_f).to eq(500.0)
        expect(json["month"]).to eq(3)
        expect(json["year"]).to eq(2026)
        expect(json["category"]).to be_present
        expect(json["category"]["id"]).to eq(category.id)
      end

      it "response includes spent_amount and remaining_amount" do
        category = create(:category)

        post "/api/budgets", params: {
          budget: { category_id: category.id, month: 3, year: 2026, limit_amount: 300 }
        }

        json = JSON.parse(response.body)
        expect(json).to have_key("spent_amount")
        expect(json).to have_key("remaining_amount")
      end
    end

    context "upsert: same category_id + month + year" do
      it "updates limit_amount and returns 201" do
        category = create(:category)
        create(:budget, category: category, month: 3, year: 2026, limit_amount: 200)

        post "/api/budgets", params: {
          budget: { category_id: category.id, month: 3, year: 2026, limit_amount: 800 }
        }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["limit_amount"].to_f).to eq(800.0)
        expect(Budget.where(category_id: category.id, month: 3, year: 2026).count).to eq(1)
      end
    end

    context "with missing/invalid params" do
      it "returns 422 with errors when limit_amount is missing" do
        category = create(:category)

        post "/api/budgets", params: {
          budget: { category_id: category.id, month: 3, year: 2026 }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json).to have_key("errors")
      end

      it "returns 422 when limit_amount is zero or negative" do
        category = create(:category)

        post "/api/budgets", params: {
          budget: { category_id: category.id, month: 3, year: 2026, limit_amount: 0 }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json).to have_key("errors")
      end
    end
  end
end
