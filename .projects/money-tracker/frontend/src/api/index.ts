const BASE_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:3000'

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`, {
    headers: { 'Content-Type': 'application/json', ...options?.headers },
    ...options,
  })
  if (!res.ok) {
    throw new Error(`HTTP ${res.status}: ${res.statusText}`)
  }
  return res.json() as Promise<T>
}

export interface Category {
  id: number
  name: string
  color: string
  icon: string
}

export type CategoryData = Omit<Category, 'id'>

export function getCategories(): Promise<Category[]> {
  return request<Category[]>('/api/categories')
}

export function createCategory(data: CategoryData): Promise<Category> {
  return request<Category>('/api/categories', {
    method: 'POST',
    body: JSON.stringify({ category: data }),
  })
}

export function updateCategory(id: number, data: Partial<CategoryData>): Promise<Category> {
  return request<Category>(`/api/categories/${id}`, {
    method: 'PATCH',
    body: JSON.stringify({ category: data }),
  })
}

export function deleteCategory(id: number): Promise<void> {
  return request<void>(`/api/categories/${id}`, { method: 'DELETE' })
}

export interface Transaction {
  id: number
  amount: number
  date: string
  notes: string | null
  category_id: number
  transaction_type: 'income' | 'expense'
  expense_kind: 'fixed' | 'variable' | null
  category: Category
}

export type TransactionFilters = {
  category_id?: number
  transaction_type?: 'income' | 'expense'
  expense_kind?: 'fixed' | 'variable'
  start_date?: string
  end_date?: string
}

export function getTransactions(filters?: TransactionFilters): Promise<Transaction[]> {
  const params = new URLSearchParams()
  if (filters) {
    for (const [key, val] of Object.entries(filters)) {
      if (val !== undefined && val !== '') params.set(key, String(val))
    }
  }
  const query = params.toString()
  return request<Transaction[]>(`/api/transactions${query ? `?${query}` : ''}`)
}

export function createTransaction(
  data: Omit<Transaction, 'id' | 'category'>,
): Promise<Transaction> {
  return request<Transaction>('/api/transactions', {
    method: 'POST',
    body: JSON.stringify({ transaction: data }),
  })
}

export function deleteTransaction(id: number): Promise<void> {
  return request<void>(`/api/transactions/${id}`, { method: 'DELETE' })
}

export interface Budget {
  id: number
  category_id: number
  month: number
  year: number
  limit_amount: number
  spent_amount: number
  remaining_amount: number
  category: Category
}

export function getBudgets(month: number, year: number): Promise<Budget[]> {
  return request<Budget[]>(`/api/budgets?month=${month}&year=${year}`)
}

export function upsertBudget(data: {
  category_id: number
  month: number
  year: number
  limit_amount: number
}): Promise<Budget> {
  return request<Budget>('/api/budgets', {
    method: 'POST',
    body: JSON.stringify({ budget: data }),
  })
}

export interface CategoryBreakdownItem {
  category: string
  color: string
  spent: number
}

export interface MonthlyTrendItem {
  label: string
  total: number
}

export interface BudgetHealthItem {
  category: string
  spent: number
  limit: number
  percent: number
}

export interface DashboardData {
  category_breakdown: CategoryBreakdownItem[]
  monthly_trend: MonthlyTrendItem[]
  budget_health: BudgetHealthItem[]
  pet_mood: 'happy' | 'worried' | 'sad'
}

export function fetchDashboard(): Promise<DashboardData> {
  return request<DashboardData>('/api/dashboard')
}
