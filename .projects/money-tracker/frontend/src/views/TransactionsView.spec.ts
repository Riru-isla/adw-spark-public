import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import TransactionsView from './TransactionsView.vue'

vi.mock('@/stores/categories', () => ({
  useCategoriesStore: vi.fn(),
}))

vi.mock('@/stores/transactions', () => ({
  useTransactionsStore: vi.fn(),
}))

import { useCategoriesStore } from '@/stores/categories'
import { useTransactionsStore } from '@/stores/transactions'

const mockFetchCategories = vi.fn()
const mockFetchTransactions = vi.fn()
const mockSetFilters = vi.fn()

function makeCategoryStore(overrides: object = {}) {
  return {
    categories: [],
    loading: false,
    error: null,
    fetchCategories: mockFetchCategories,
    ...overrides,
  }
}

function makeTxStore(overrides: object = {}) {
  return {
    transactions: [],
    loading: false,
    error: null,
    fetchTransactions: mockFetchTransactions,
    setFilters: mockSetFilters,
    ...overrides,
  }
}

const globalConfig = {
  stubs: {
    TransactionForm: { name: 'TransactionForm', template: '<div />' },
  },
}

beforeEach(() => {
  setActivePinia(createPinia())
  vi.clearAllMocks()
  ;(useCategoriesStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue(makeCategoryStore())
  ;(useTransactionsStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue(makeTxStore())
})

describe('TransactionsView', () => {
  it('renders "No transactions found." when transactions is empty and not loading', async () => {
    const wrapper = mount(TransactionsView, { global: globalConfig })
    await flushPromises()
    const msg = wrapper.find('.state-msg')
    expect(msg.exists()).toBe(true)
    expect(msg.text()).toBe('No transactions found.')
  })

  it('renders "Loading…" when loading is true', async () => {
    ;(useTransactionsStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue(
      makeTxStore({ loading: true }),
    )
    const wrapper = mount(TransactionsView, { global: globalConfig })
    await flushPromises()
    const msg = wrapper.find('.state-msg')
    expect(msg.exists()).toBe(true)
    expect(msg.text()).toBe('Loading…')
  })
})
