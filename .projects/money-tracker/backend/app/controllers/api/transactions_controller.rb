module Api
  class TransactionsController < ApplicationController
    before_action :set_transaction, only: [:destroy]

    def index
      transactions = Transaction.includes(:category).order(date: :desc)

      transactions = transactions.where(category_id: params[:category_id]) if params[:category_id].present?
      transactions = transactions.where(transaction_type: params[:transaction_type]) if params[:transaction_type].present?
      transactions = transactions.where(expense_kind: params[:expense_kind]) if params[:expense_kind].present?

      if params[:start_date].present? && params[:end_date].present?
        transactions = transactions.where(date: params[:start_date]..params[:end_date])
      end

      render json: transactions.as_json(include: :category)
    end

    def create
      transaction = Transaction.new(transaction_params)
      if transaction.save
        render json: transaction.as_json(include: :category), status: :created
      else
        render json: { errors: transaction.errors }, status: :unprocessable_entity
      end
    rescue ArgumentError => e
      render json: { errors: { base: [e.message] } }, status: :unprocessable_entity
    end

    def destroy
      @transaction.destroy
      head :no_content
    end

    private

    def set_transaction
      @transaction = Transaction.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Transaction not found" }, status: :not_found
    end

    def transaction_params
      params.require(:transaction).permit(:amount, :date, :notes, :category_id, :transaction_type, :expense_kind)
    end
  end
end
