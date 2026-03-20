# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

default_categories = [
  { name: "Rent",          icon: "🏠", color: "#EF4444" },
  { name: "Groceries",     icon: "🛒", color: "#F97316" },
  { name: "Dining Out",    icon: "🍽️", color: "#EAB308" },
  { name: "Transport",     icon: "🚌", color: "#22C55E" },
  { name: "Hobbies",       icon: "🎨", color: "#3B82F6" },
  { name: "Entertainment", icon: "🎬", color: "#8B5CF6" },
  { name: "Utilities",     icon: "💡", color: "#06B6D4" },
  { name: "Income",        icon: "💰", color: "#10B981" }
]

default_categories.each do |attrs|
  Category.find_or_create_by!(name: attrs[:name]) do |cat|
    cat.icon  = attrs[:icon]
    cat.color = attrs[:color]
  end
end

puts "Seeded #{Category.count} categories."
