module Api
  class CategoriesController < ApplicationController
    before_action :set_category, only: [:update, :destroy]

    def index
      categories = Category.order(:name)
      render json: categories
    end

    def create
      category = Category.new(category_params)
      if category.save
        render json: category, status: :created
      else
        render json: { errors: category.errors }, status: :unprocessable_entity
      end
    end

    def update
      if @category.update(category_params)
        render json: @category
      else
        render json: { errors: @category.errors }, status: :unprocessable_entity
      end
    end

    def destroy
      if @category.transactions.exists?
        render json: { error: "Cannot delete category with existing transactions" }, status: :unprocessable_entity
      else
        @category.destroy
        head :no_content
      end
    end

    private

    def set_category
      @category = Category.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Category not found" }, status: :not_found
    end

    def category_params
      params.require(:category).permit(:name, :color, :icon)
    end
  end
end
