module Api
  class BudgetsController < ApplicationController
    def index
      month = (params[:month] || Date.today.month).to_i
      year  = (params[:year]  || Date.today.year).to_i

      budgets = Budget.includes(:category).where(month: month, year: year)

      start_date = Date.new(year, month, 1)
      end_date   = start_date.end_of_month

      spending = Transaction
        .where(transaction_type: "expense")
        .where(date: start_date..end_date)
        .group(:category_id)
        .sum(:amount)

      render json: budgets.map { |b| budget_json(b, spending.fetch(b.category_id, 0)) }
    end

    def create
      budget = Budget.find_or_initialize_by(
        category_id: budget_params[:category_id],
        month:       budget_params[:month],
        year:        budget_params[:year]
      )
      budget.limit_amount = budget_params[:limit_amount]

      if budget.save
        start_date = Date.new(budget.year, budget.month, 1)
        end_date   = start_date.end_of_month
        spent = Transaction
          .where(category_id: budget.category_id, transaction_type: "expense")
          .where(date: start_date..end_date)
          .sum(:amount)
        budget.reload
        render json: budget_json(budget, spent), status: :created
      else
        render json: { errors: budget.errors }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Not found" }, status: :not_found
    end

    private

    def budget_params
      params.require(:budget).permit(:category_id, :month, :year, :limit_amount)
    end

    def budget_json(budget, spent_amount)
      spent     = spent_amount.to_f
      remaining = budget.limit_amount.to_f - spent
      budget.as_json(only: [:id, :month, :year, :limit_amount]).merge(
        "spent_amount"     => spent,
        "remaining_amount" => remaining,
        "category"         => budget.category.as_json(only: [:id, :name, :icon, :color])
      )
    end
  end
end
