import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { getBudgets, upsertBudget, type Budget } from '@/api/index'

export const useBudgetsStore = defineStore('budgets', () => {
  const now = new Date()
  const budgets = ref<Budget[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)
  const month = ref(now.getMonth() + 1)
  const year = ref(now.getFullYear())

  const totalLimit = computed(() => budgets.value.reduce((sum, b) => sum + b.limit_amount, 0))
  const totalSpent = computed(() => budgets.value.reduce((sum, b) => sum + b.spent_amount, 0))

  async function fetchBudgets(m: number, y: number) {
    loading.value = true
    error.value = null
    try {
      budgets.value = await getBudgets(m, y)
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to load budgets'
    } finally {
      loading.value = false
    }
  }

  async function saveBudget(data: {
    category_id: number
    month: number
    year: number
    limit_amount: number
  }) {
    await upsertBudget(data)
    await fetchBudgets(month.value, year.value)
  }

  async function setMonth(m: number, y: number) {
    month.value = m
    year.value = y
    await fetchBudgets(m, y)
  }

  return {
    budgets,
    loading,
    error,
    month,
    year,
    totalLimit,
    totalSpent,
    fetchBudgets,
    saveBudget,
    setMonth,
  }
})
