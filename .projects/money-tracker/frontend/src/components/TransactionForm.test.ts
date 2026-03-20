import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import TransactionForm from './TransactionForm.vue'

vi.mock('@/api/index', () => ({
  getTransactions: vi.fn(),
  createTransaction: vi.fn(),
  deleteTransaction: vi.fn(),
}))

import * as api from '@/api/index'

const mockCategories = [
  { id: 1, name: 'Food', color: '#ff0000', icon: '🍕' },
  { id: 2, name: 'Transport', color: '#0000ff', icon: '🚗' },
]

const mockCreated = {
  id: 99,
  amount: 25,
  date: '2026-03-01',
  notes: null,
  category_id: 1,
  transaction_type: 'expense' as const,
  expense_kind: 'variable' as const,
  category: mockCategories[0]!,
}

beforeEach(() => {
  setActivePinia(createPinia())
  vi.clearAllMocks()
})

async function fillValidForm(wrapper: ReturnType<typeof mount>) {
  await wrapper.find('input#tx-amount').setValue('25')
  await wrapper.find('input#tx-date').setValue('2026-03-01')
  await wrapper.find('select#tx-type').setValue('expense')
  // expense_kind appears after selecting 'expense'
  await wrapper.find('select#tx-kind').setValue('variable')
  await wrapper.find('select#tx-category').setValue('1')
}

describe('TransactionForm', () => {
  it('renders required fields', () => {
    const wrapper = mount(TransactionForm, { props: { categories: mockCategories } })
    expect(wrapper.find('input#tx-amount').exists()).toBe(true)
    expect(wrapper.find('input#tx-date').exists()).toBe(true)
    expect(wrapper.find('select#tx-type').exists()).toBe(true)
    expect(wrapper.find('select#tx-category').exists()).toBe(true)
  })

  it('does not show expense_kind when type is income', async () => {
    const wrapper = mount(TransactionForm, { props: { categories: mockCategories } })
    await wrapper.find('select#tx-type').setValue('income')
    expect(wrapper.find('select#tx-kind').exists()).toBe(false)
  })

  it('shows expense_kind when type is expense', async () => {
    const wrapper = mount(TransactionForm, { props: { categories: mockCategories } })
    await wrapper.find('select#tx-type').setValue('expense')
    expect(wrapper.find('select#tx-kind').exists()).toBe(true)
  })

  it('calls addTransaction and emits saved on valid submit', async () => {
    vi.mocked(api.createTransaction).mockResolvedValue(mockCreated)
    const wrapper = mount(TransactionForm, { props: { categories: mockCategories } })

    await fillValidForm(wrapper)
    await wrapper.find('form').trigger('submit')
    await wrapper.vm.$nextTick()

    expect(api.createTransaction).toHaveBeenCalled()
    expect(wrapper.emitted('saved')).toBeTruthy()
  })

  it('shows validation errors when required fields are missing', async () => {
    const wrapper = mount(TransactionForm, { props: { categories: mockCategories } })
    // Clear date to trigger date validation error
    await wrapper.find('input#tx-date').setValue('')
    await wrapper.find('form').trigger('submit')

    expect(wrapper.emitted('saved')).toBeFalsy()
    expect(wrapper.text()).toContain('Amount is required')
    expect(wrapper.text()).toContain('Date is required')
    expect(wrapper.text()).toContain('Type is required')
    expect(wrapper.text()).toContain('Category is required')
  })

  it('shows expense_kind error when type is expense and kind is missing', async () => {
    const wrapper = mount(TransactionForm, { props: { categories: mockCategories } })
    await wrapper.find('input#tx-amount').setValue('10')
    await wrapper.find('input#tx-date').setValue('2026-03-01')
    await wrapper.find('select#tx-type').setValue('expense')
    // skip expense_kind selection
    await wrapper.find('select#tx-category').setValue('1')
    await wrapper.find('form').trigger('submit')

    expect(wrapper.emitted('saved')).toBeFalsy()
    expect(wrapper.text()).toContain('Expense kind is required')
  })
})
