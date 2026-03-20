import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useBudgetsStore } from './budgets'

vi.mock('@/api/index', () => ({
  getBudgets: vi.fn(),
  upsertBudget: vi.fn(),
}))

import * as api from '@/api/index'

const mockCategory = { id: 1, name: 'Food', color: '#ff0000', icon: '🍕' }

const mockBudget = {
  id: 1,
  category_id: 1,
  month: 3,
  year: 2026,
  limit_amount: 200,
  spent_amount: 100,
  remaining_amount: 100,
  category: mockCategory,
}

beforeEach(() => {
  setActivePinia(createPinia())
  vi.clearAllMocks()
})

describe('useBudgetsStore', () => {
  describe('fetchBudgets', () => {
    it('populates budgets and sets loading correctly', async () => {
      vi.mocked(api.getBudgets).mockResolvedValue([mockBudget])
      const store = useBudgetsStore()
      await store.fetchBudgets(3, 2026)
      expect(store.budgets).toEqual([mockBudget])
      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })

    it('sets error on failure', async () => {
      vi.mocked(api.getBudgets).mockRejectedValue(new Error('Network error'))
      const store = useBudgetsStore()
      await store.fetchBudgets(3, 2026)
      expect(store.budgets).toEqual([])
      expect(store.error).toBe('Network error')
      expect(store.loading).toBe(false)
    })
  })

  describe('saveBudget', () => {
    it('calls upsertBudget then re-fetches', async () => {
      vi.mocked(api.upsertBudget).mockResolvedValue(mockBudget)
      vi.mocked(api.getBudgets).mockResolvedValue([mockBudget])
      const store = useBudgetsStore()

      await store.saveBudget({ category_id: 1, month: 3, year: 2026, limit_amount: 200 })

      expect(api.upsertBudget).toHaveBeenCalledWith({
        category_id: 1,
        month: 3,
        year: 2026,
        limit_amount: 200,
      })
      expect(api.getBudgets).toHaveBeenCalled()
    })
  })

  describe('totalLimit and totalSpent', () => {
    it('totalLimit sums all limit_amounts', async () => {
      const budget2 = { ...mockBudget, id: 2, limit_amount: 300, spent_amount: 50, remaining_amount: 250 }
      vi.mocked(api.getBudgets).mockResolvedValue([mockBudget, budget2])
      const store = useBudgetsStore()
      await store.fetchBudgets(3, 2026)
      expect(store.totalLimit).toBe(500)
    })

    it('totalSpent sums all spent_amounts', async () => {
      const budget2 = { ...mockBudget, id: 2, limit_amount: 300, spent_amount: 50, remaining_amount: 250 }
      vi.mocked(api.getBudgets).mockResolvedValue([mockBudget, budget2])
      const store = useBudgetsStore()
      await store.fetchBudgets(3, 2026)
      expect(store.totalSpent).toBe(150)
    })
  })
})
