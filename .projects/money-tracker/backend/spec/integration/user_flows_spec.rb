require 'rails_helper'

RSpec.describe 'User flows', type: :request do
  let(:today) { Date.today }

  describe 'Flow 1: category + transaction + dashboard' do
    it 'category_breakdown includes the category with a non-zero total and pet_mood is present' do
      # Create a category via API
      post '/api/categories', params: { category: { name: 'Groceries', icon: '🛒', color: '#FF6384' } }
      expect(response).to have_http_status(:created)
      category = JSON.parse(response.body)
      category_id = category['id']

      # Create an expense transaction against that category
      post '/api/transactions', params: {
        transaction: {
          category_id: category_id,
          amount: 85.50,
          date: today.to_s,
          transaction_type: 'expense',
          expense_kind: 'variable',
          notes: 'Weekly groceries'
        }
      }
      expect(response).to have_http_status(:created)

      # Dashboard should reflect the category breakdown
      get '/api/dashboard'
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body).to have_key('pet_mood')
      expect(body['pet_mood']).to be_a(String)

      breakdown = body['category_breakdown']
      expect(breakdown).to be_an(Array)
      groceries_entry = breakdown.find { |e| e['name'] == 'Groceries' }
      expect(groceries_entry).not_to be_nil
      expect(groceries_entry['spent'].to_f).to be > 0
    end
  end

  describe 'Flow 2: category + transaction + budget + budget query' do
    it 'budget response includes correct spent_amount, limit_amount, and remaining_amount' do
      # Create a category via API
      post '/api/categories', params: { category: { name: 'Utilities', icon: '💡', color: '#36A2EB' } }
      expect(response).to have_http_status(:created)
      category = JSON.parse(response.body)
      category_id = category['id']

      # Create an expense transaction to generate spend
      post '/api/transactions', params: {
        transaction: {
          category_id: category_id,
          amount: 120.0,
          date: today.to_s,
          transaction_type: 'expense',
          expense_kind: 'fixed',
          notes: 'Electric bill'
        }
      }
      expect(response).to have_http_status(:created)

      # Set a budget limit for the current month
      limit_amount = 300.0
      post '/api/budgets', params: {
        budget: {
          category_id: category_id,
          month: today.month,
          year: today.year,
          limit_amount: limit_amount
        }
      }
      expect(response).to have_http_status(:created)

      # Query budgets and verify computed amounts
      get '/api/budgets', params: { month: today.month, year: today.year }
      expect(response).to have_http_status(:ok)
      budgets = JSON.parse(response.body)

      utilities_budget = budgets.find { |b| b['category']['id'] == category_id }
      expect(utilities_budget).not_to be_nil
      expect(utilities_budget['spent_amount'].to_f).to be > 0
      expect(utilities_budget['limit_amount'].to_f).to eq(limit_amount)
      expect(utilities_budget['remaining_amount'].to_f).to eq(
        limit_amount - utilities_budget['spent_amount'].to_f
      )
    end
  end
end
