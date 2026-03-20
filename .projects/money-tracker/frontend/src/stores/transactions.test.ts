import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useTransactionsStore } from './transactions'

vi.mock('@/api/index', () => ({
  getTransactions: vi.fn(),
  createTransaction: vi.fn(),
  deleteTransaction: vi.fn(),
}))

import * as api from '@/api/index'

const mockCategory = { id: 1, name: 'Food', color: '#ff0000', icon: '🍕' }

const mockTransaction = {
  id: 1,
  amount: 50,
  date: '2026-01-15',
  notes: 'Lunch',
  category_id: 1,
  transaction_type: 'expense' as const,
  expense_kind: 'variable' as const,
  category: mockCategory,
}

beforeEach(() => {
  setActivePinia(createPinia())
  vi.clearAllMocks()
})

describe('useTransactionsStore', () => {
  describe('fetchTransactions', () => {
    it('loads transactions into state', async () => {
      vi.mocked(api.getTransactions).mockResolvedValue([mockTransaction])
      const store = useTransactionsStore()
      await store.fetchTransactions()
      expect(store.transactions).toEqual([mockTransaction])
      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })

    it('sets error on failure', async () => {
      vi.mocked(api.getTransactions).mockRejectedValue(new Error('Network error'))
      const store = useTransactionsStore()
      await store.fetchTransactions()
      expect(store.transactions).toEqual([])
      expect(store.error).toBe('Network error')
    })
  })

  describe('addTransaction', () => {
    it('prepends new transaction to list', async () => {
      vi.mocked(api.getTransactions).mockResolvedValue([mockTransaction])
      vi.mocked(api.createTransaction).mockResolvedValue({ ...mockTransaction, id: 2, amount: 100 })

      const store = useTransactionsStore()
      await store.fetchTransactions()

      await store.addTransaction({
        amount: 100,
        date: '2026-01-20',
        notes: null,
        category_id: 1,
        transaction_type: 'expense',
        expense_kind: 'fixed',
      })

      expect(store.transactions[0]!.id).toBe(2)
      expect(store.transactions.length).toBe(2)
    })
  })

  describe('removeTransaction', () => {
    it('removes transaction from list', async () => {
      vi.mocked(api.getTransactions).mockResolvedValue([mockTransaction])
      vi.mocked(api.deleteTransaction).mockResolvedValue(undefined)

      const store = useTransactionsStore()
      await store.fetchTransactions()
      await store.removeTransaction(1)

      expect(store.transactions).toEqual([])
      expect(api.deleteTransaction).toHaveBeenCalledWith(1)
    })
  })

  describe('setFilters', () => {
    it('updates filters and re-fetches', async () => {
      vi.mocked(api.getTransactions).mockResolvedValue([])
      const store = useTransactionsStore()

      await store.setFilters({ transaction_type: 'expense' })

      expect(store.filters).toEqual({ transaction_type: 'expense' })
      expect(api.getTransactions).toHaveBeenCalledWith({ transaction_type: 'expense' })
    })
  })
})
