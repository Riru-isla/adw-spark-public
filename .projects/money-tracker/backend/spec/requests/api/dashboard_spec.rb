require 'rails_helper'

RSpec.describe "GET /api/dashboard", type: :request do
  let(:today) { Date.today }
  let(:current_month) { today.month }
  let(:current_year)  { today.year }

  def get_dashboard
    get "/api/dashboard"
    JSON.parse(response.body)
  end

  context "with no data" do
    it "returns 200 with all top-level keys" do
      get "/api/dashboard"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.keys).to match_array(%w[category_breakdown monthly_trend budget_health pet_mood])
    end

    it "returns monthly_trend with exactly 6 entries" do
      body = get_dashboard
      expect(body["monthly_trend"].length).to eq(6)
    end

    it "returns all zeros in monthly_trend when no transactions" do
      body = get_dashboard
      body["monthly_trend"].each do |entry|
        expect(entry["total"]).to eq(0.0)
      end
    end

    it "returns monthly_trend in chronological order" do
      body = get_dashboard
      trend = body["monthly_trend"]
      dates = trend.map { |e| Date.new(e["year"], e["month"], 1) }
      expect(dates).to eq(dates.sort)
    end

    it "returns budget_health with 0 when no budgets" do
      body = get_dashboard
      health = body["budget_health"]
      expect(health["total_budgeted"]).to eq(0.0)
      expect(health["total_spent"]).to eq(0.0)
      expect(health["percentage"]).to eq(0.0)
    end

    it "returns pet_mood as happy when no budgets" do
      body = get_dashboard
      expect(body["pet_mood"]).to eq("happy")
    end
  end

  context "category_breakdown" do
    let(:cat1) { create(:category, name: "Food", icon: "🍕", color: "#FF0000") }
    let(:cat2) { create(:category, name: "Transport", icon: "🚌", color: "#00FF00") }

    before do
      # current month expenses
      create(:transaction, category: cat1, amount: 100.0, date: today, transaction_type: "expense")
      create(:transaction, category: cat1, amount: 50.0,  date: today, transaction_type: "expense")
      create(:transaction, category: cat2, amount: 30.0,  date: today, transaction_type: "expense")
      # income should be excluded
      create(:transaction, category: cat1, amount: 999.0, date: today, transaction_type: "income", expense_kind: nil)
      # previous month expense should be excluded
      create(:transaction, category: cat1, amount: 200.0, date: today - 1.month, transaction_type: "expense")
    end

    it "groups expenses by category with correct totals" do
      body = get_dashboard
      breakdown = body["category_breakdown"]
      food_entry = breakdown.find { |e| e["name"] == "Food" }
      transport_entry = breakdown.find { |e| e["name"] == "Transport" }

      expect(food_entry).not_to be_nil
      expect(food_entry["spent"]).to eq(150.0)
      expect(food_entry["icon"]).to eq("🍕")
      expect(food_entry["color"]).to eq("#FF0000")

      expect(transport_entry).not_to be_nil
      expect(transport_entry["spent"]).to eq(30.0)
    end

    it "excludes income transactions" do
      body = get_dashboard
      breakdown = body["category_breakdown"]
      food_entry = breakdown.find { |e| e["name"] == "Food" }
      # 999 income should not be included, only 150 from expenses
      expect(food_entry["spent"]).to eq(150.0)
    end

    it "excludes transactions from other months" do
      body = get_dashboard
      breakdown = body["category_breakdown"]
      food_entry = breakdown.find { |e| e["name"] == "Food" }
      expect(food_entry["spent"]).to eq(150.0)
    end
  end

  context "monthly_trend" do
    let(:cat) { create(:category) }

    it "covers exactly 6 months from 5 months ago to current" do
      body = get_dashboard
      trend = body["monthly_trend"]
      expect(trend.length).to eq(6)
      first_entry = trend.first
      last_entry  = trend.last
      expected_start = today.beginning_of_month - 5.months
      expect(first_entry["year"]).to eq(expected_start.year)
      expect(first_entry["month"]).to eq(expected_start.month)
      expect(last_entry["year"]).to eq(current_year)
      expect(last_entry["month"]).to eq(current_month)
    end

    it "fills zero for months without transactions" do
      # only add transaction for current month
      create(:transaction, category: cat, amount: 75.0, date: today, transaction_type: "expense")
      body = get_dashboard
      trend = body["monthly_trend"]
      # All entries except the last (current month) should be 0
      trend[0..4].each { |e| expect(e["total"]).to eq(0.0) }
      expect(trend.last["total"]).to eq(75.0)
    end

    it "includes correct totals per month" do
      old_date = today.beginning_of_month - 3.months
      create(:transaction, category: cat, amount: 120.0, date: old_date, transaction_type: "expense")
      create(:transaction, category: cat, amount: 80.0,  date: today,    transaction_type: "expense")

      body = get_dashboard
      trend = body["monthly_trend"]

      old_entry = trend.find { |e| e["year"] == old_date.year && e["month"] == old_date.month }
      cur_entry = trend.find { |e| e["year"] == current_year && e["month"] == current_month }

      expect(old_entry["total"]).to eq(120.0)
      expect(cur_entry["total"]).to eq(80.0)
    end

    it "excludes income from trend" do
      create(:transaction, category: cat, amount: 500.0, date: today, transaction_type: "income", expense_kind: nil)
      create(:transaction, category: cat, amount: 40.0,  date: today, transaction_type: "expense")
      body = get_dashboard
      cur_entry = body["monthly_trend"].find { |e| e["month"] == current_month && e["year"] == current_year }
      expect(cur_entry["total"]).to eq(40.0)
    end

    it "includes a human-readable label" do
      body = get_dashboard
      body["monthly_trend"].each do |entry|
        expect(entry["label"]).to match(/\A[A-Z][a-z]{2}\z/)
      end
    end
  end

  context "budget_health" do
    let(:cat1) { create(:category) }
    let(:cat2) { create(:category) }

    before do
      create(:budget, category: cat1, month: current_month, year: current_year, limit_amount: 400.0)
      create(:budget, category: cat2, month: current_month, year: current_year, limit_amount: 600.0)
      create(:transaction, category: cat1, amount: 200.0, date: today, transaction_type: "expense")
      create(:transaction, category: cat2, amount: 300.0, date: today, transaction_type: "expense")
    end

    it "sums all budget limits" do
      body = get_dashboard
      expect(body["budget_health"]["total_budgeted"]).to eq(1000.0)
    end

    it "sums current month expenses" do
      body = get_dashboard
      expect(body["budget_health"]["total_spent"]).to eq(500.0)
    end

    it "calculates percentage correctly" do
      body = get_dashboard
      # 500 / 1000 * 100 = 50.0
      expect(body["budget_health"]["percentage"]).to eq(50.0)
    end
  end

  context "pet_mood thresholds" do
    let(:cat) { create(:category) }

    def setup_spending(spent:, budgeted:)
      Budget.where(month: current_month, year: current_year).destroy_all
      Transaction.destroy_all
      create(:budget, category: cat, month: current_month, year: current_year, limit_amount: budgeted)
      create(:transaction, category: cat, amount: spent, date: today, transaction_type: "expense") if spent > 0
    end

    it "returns happy when percentage < 80" do
      setup_spending(spent: 70.0, budgeted: 100.0)
      body = get_dashboard
      expect(body["pet_mood"]).to eq("happy")
    end

    it "returns worried when percentage is exactly 80" do
      setup_spending(spent: 80.0, budgeted: 100.0)
      body = get_dashboard
      expect(body["pet_mood"]).to eq("worried")
    end

    it "returns worried when percentage is 100" do
      setup_spending(spent: 100.0, budgeted: 100.0)
      body = get_dashboard
      expect(body["pet_mood"]).to eq("worried")
    end

    it "returns sad when percentage > 100" do
      setup_spending(spent: 150.0, budgeted: 100.0)
      body = get_dashboard
      expect(body["pet_mood"]).to eq("sad")
    end

    it "returns happy when no budgets (division by zero guard)" do
      # No budgets at all
      body = get_dashboard
      expect(body["pet_mood"]).to eq("happy")
    end
  end
end
