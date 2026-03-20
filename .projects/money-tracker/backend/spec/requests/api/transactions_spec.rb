require "rails_helper"

RSpec.describe "Api::Transactions", type: :request do
  describe "GET /api/transactions" do
    it "returns 200 ordered by date descending" do
      category = create(:category)
      create(:transaction, category: category, date: "2026-01-01", amount: 10)
      create(:transaction, category: category, date: "2026-01-15", amount: 20)
      create(:transaction, category: category, date: "2026-01-10", amount: 30)

      get "/api/transactions"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      expect(json.length).to eq(3)
      dates = json.map { |t| t["date"] }
      expect(dates).to eq(dates.sort.reverse)
    end

    it "filters by category_id" do
      cat1 = create(:category)
      cat2 = create(:category)
      create(:transaction, category: cat1)
      create(:transaction, category: cat2)

      get "/api/transactions", params: { category_id: cat1.id }

      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["category_id"]).to eq(cat1.id)
    end

    it "filters by transaction_type" do
      category = create(:category)
      create(:transaction, category: category, transaction_type: "expense")
      create(:transaction, category: category, transaction_type: "income")

      get "/api/transactions", params: { transaction_type: "expense" }

      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["transaction_type"]).to eq("expense")
    end

    it "filters by expense_kind" do
      category = create(:category)
      create(:transaction, category: category, expense_kind: "fixed")
      create(:transaction, category: category, expense_kind: "variable")

      get "/api/transactions", params: { expense_kind: "fixed" }

      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["expense_kind"]).to eq("fixed")
    end

    it "filters by date range" do
      category = create(:category)
      create(:transaction, category: category, date: "2026-01-05")
      create(:transaction, category: category, date: "2026-01-15")
      create(:transaction, category: category, date: "2026-02-01")

      get "/api/transactions", params: { start_date: "2026-01-01", end_date: "2026-01-31" }

      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end
  end

  describe "POST /api/transactions" do
    context "with valid params" do
      it "returns 201 with created transaction" do
        category = create(:category)

        post "/api/transactions", params: {
          transaction: {
            amount: 99.99,
            date: "2026-03-01",
            notes: "Groceries",
            category_id: category.id,
            transaction_type: "expense",
            expense_kind: "variable"
          }
        }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["amount"]).to eq("99.99")
        expect(json["notes"]).to eq("Groceries")
        expect(json["transaction_type"]).to eq("expense")
        expect(json["category"]).to be_present
      end
    end

    context "with missing required fields" do
      it "returns 422 with errors" do
        post "/api/transactions", params: {
          transaction: { notes: "No amount or date" }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json).to have_key("errors")
      end
    end

    context "with invalid enum value" do
      it "returns 422 with errors" do
        category = create(:category)

        post "/api/transactions", params: {
          transaction: {
            amount: 10,
            date: "2026-03-01",
            category_id: category.id,
            transaction_type: "invalid_type"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json).to have_key("errors")
      end
    end
  end

  describe "DELETE /api/transactions/:id" do
    it "returns 204 and removes the transaction" do
      transaction = create(:transaction)

      delete "/api/transactions/#{transaction.id}"

      expect(response).to have_http_status(:no_content)
      expect(Transaction.exists?(transaction.id)).to be false
    end

    it "returns 404 for unknown id" do
      delete "/api/transactions/99999"

      expect(response).to have_http_status(:not_found)
    end
  end
end
