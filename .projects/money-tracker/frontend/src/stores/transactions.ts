import { ref } from 'vue'
import { defineStore } from 'pinia'
import {
  getTransactions,
  createTransaction,
  deleteTransaction,
  type Transaction,
  type TransactionFilters,
} from '@/api/index'

export const useTransactionsStore = defineStore('transactions', () => {
  const transactions = ref<Transaction[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)
  const filters = ref<TransactionFilters>({})

  async function fetchTransactions() {
    loading.value = true
    error.value = null
    try {
      transactions.value = await getTransactions(filters.value)
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to load transactions'
    } finally {
      loading.value = false
    }
  }

  async function addTransaction(data: Omit<Transaction, 'id' | 'category'>) {
    const created = await createTransaction(data)
    transactions.value.unshift(created)
  }

  async function removeTransaction(id: number) {
    await deleteTransaction(id)
    transactions.value = transactions.value.filter((t) => t.id !== id)
  }

  async function setFilters(newFilters: TransactionFilters) {
    filters.value = newFilters
    await fetchTransactions()
  }

  return { transactions, loading, error, filters, fetchTransactions, addTransaction, removeTransaction, setFilters }
})
