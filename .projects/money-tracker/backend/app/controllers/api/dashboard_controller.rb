module Api
  class DashboardController < ApplicationController
    def show
      render json: {
        category_breakdown: category_breakdown,
        monthly_trend:      monthly_trend,
        budget_health:      budget_health,
        pet_mood:           pet_mood
      }
    end

    private

    def current_month_range
      today = Date.today
      Date.new(today.year, today.month, 1)..today.end_of_month
    end

    def category_breakdown
      Transaction
        .where(transaction_type: "expense", date: current_month_range)
        .joins(:category)
        .group(:category_id, "categories.name", "categories.icon", "categories.color")
        .sum(:amount)
        .map do |(category_id, name, icon, color), total|
          {
            category_id: category_id,
            name:        name,
            icon:        icon,
            color:       color,
            spent:       total.to_f.round(2)
          }
        end
    end

    def monthly_trend
      start_date = Date.today.beginning_of_month - 5.months

      raw = Transaction
        .where(transaction_type: "expense")
        .where(date: start_date..Date.today.end_of_month)
        .group(
          Arel.sql("EXTRACT(YEAR FROM \"transactions\".\"date\")::int"),
          Arel.sql("EXTRACT(MONTH FROM \"transactions\".\"date\")::int")
        )
        .sum(:amount)
      totals_by_month = raw.transform_keys { |k| [k[0].to_i, k[1].to_i] }

      (0..5).map do |offset|
        month_date = start_date + offset.months
        year  = month_date.year
        month = month_date.month
        total = totals_by_month.fetch([year, month], 0)
        {
          year:  year,
          month: month,
          label: month_date.strftime("%b"),
          total: total.to_f.round(2)
        }
      end
    end

    def budget_health
      @budget_health ||= begin
        today = Date.today
        budgets = Budget.where(month: today.month, year: today.year)

        total_budgeted = budgets.sum(:limit_amount).to_f.round(2)
        total_spent    = Transaction
          .where(transaction_type: "expense", date: current_month_range)
          .sum(:amount).to_f.round(2)

        percentage = total_budgeted > 0 ? (total_spent / total_budgeted * 100).round(1) : 0.0

        { total_budgeted: total_budgeted, total_spent: total_spent, percentage: percentage }
      end
    end

    def pet_mood
      health = budget_health
      if health[:total_budgeted] == 0.0
        "happy"
      elsif health[:percentage] < 80
        "happy"
      elsif health[:percentage] <= 100
        "worried"
      else
        "sad"
      end
    end
  end
end
