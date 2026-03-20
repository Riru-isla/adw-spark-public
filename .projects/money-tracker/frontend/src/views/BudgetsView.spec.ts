import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import BudgetsView from './BudgetsView.vue'

vi.mock('@/stores/budgets', () => ({
  useBudgetsStore: vi.fn(),
}))

vi.mock('@/stores/categories', () => ({
  useCategoriesStore: vi.fn(),
}))

import { useBudgetsStore } from '@/stores/budgets'
import { useCategoriesStore } from '@/stores/categories'

const mockFetchBudgets = vi.fn()
const mockSaveBudget = vi.fn()
const mockSetMonth = vi.fn()
const mockFetchCategories = vi.fn()

const mockCategories = [
  { id: 1, name: 'Food', color: '#ff0000', icon: '🍕' },
  { id: 2, name: 'Transport', color: '#0000ff', icon: '🚗' },
]

const mockBudgets = [
  {
    id: 1,
    category_id: 1,
    month: 3,
    year: 2026,
    limit_amount: 200,
    spent_amount: 100,
    remaining_amount: 100,
    category: mockCategories[0],
  },
  {
    id: 2,
    category_id: 2,
    month: 3,
    year: 2026,
    limit_amount: 100,
    spent_amount: 80,
    remaining_amount: 20,
    category: mockCategories[1],
  },
]

function makeBudgetStore(overrides: object = {}) {
  return {
    budgets: mockBudgets,
    loading: false,
    error: null,
    month: 3,
    year: 2026,
    totalLimit: 300,
    totalSpent: 180,
    fetchBudgets: mockFetchBudgets,
    saveBudget: mockSaveBudget,
    setMonth: mockSetMonth,
    ...overrides,
  }
}

function makeCategoryStore(overrides: object = {}) {
  return {
    categories: mockCategories,
    loading: false,
    error: null,
    fetchCategories: mockFetchCategories,
    ...overrides,
  }
}

beforeEach(() => {
  setActivePinia(createPinia())
  vi.clearAllMocks()
  ;(useBudgetsStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue(makeBudgetStore())
  ;(useCategoriesStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue(makeCategoryStore())
})

describe('BudgetsView', () => {
  it('renders a progress bar for each budget', async () => {
    const wrapper = mount(BudgetsView)
    await flushPromises()
    const bars = wrapper.findAll('.progress-bar-fill')
    expect(bars.length).toBe(mockBudgets.length)
  })

  it('progress bar width reflects spent/limit ratio', async () => {
    const wrapper = mount(BudgetsView)
    await flushPromises()
    const bars = wrapper.findAll('.progress-bar-fill')
    // First budget: 100/200 = 50%
    expect(bars[0]!.attributes('style')).toContain('50%')
    // Second budget: 80/100 = 80%
    expect(bars[1]!.attributes('style')).toContain('80%')
  })

  it('progress bar has correct color class at <70%, 70-90%, >90%', async () => {
    const overBudget = {
      id: 3, category_id: 1, month: 3, year: 2026,
      limit_amount: 100, spent_amount: 95, remaining_amount: 5,
      category: mockCategories[0],
    }
    const warningBudget = {
      id: 4, category_id: 2, month: 3, year: 2026,
      limit_amount: 100, spent_amount: 75, remaining_amount: 25,
      category: mockCategories[1],
    }
    const okBudget = {
      id: 5, category_id: 1, month: 3, year: 2026,
      limit_amount: 100, spent_amount: 50, remaining_amount: 50,
      category: mockCategories[0],
    }
    ;(useBudgetsStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue(
      makeBudgetStore({ budgets: [overBudget, warningBudget, okBudget] }),
    )
    const wrapper = mount(BudgetsView)
    await flushPromises()
    const bars = wrapper.findAll('.progress-bar-fill')
    expect(bars[0]!.classes()).toContain('bar-red')
    expect(bars[1]!.classes()).toContain('bar-yellow')
    expect(bars[2]!.classes()).toContain('bar-green')
  })

  it('month navigation buttons call setMonth with correct args', async () => {
    const wrapper = mount(BudgetsView)
    await flushPromises()

    expect(wrapper.text()).toContain('March 2026')

    await wrapper.find('[data-testid="prev-month"]').trigger('click')
    expect(mockSetMonth).toHaveBeenCalledWith(2, 2026)

    await wrapper.find('[data-testid="next-month"]').trigger('click')
    expect(mockSetMonth).toHaveBeenCalledWith(4, 2026)
  })

  it('"Set Budget" button opens the form modal', async () => {
    const wrapper = mount(BudgetsView)
    await flushPromises()
    expect(wrapper.find('.modal').exists()).toBe(false)
    await wrapper.find('.btn-primary').trigger('click')
    expect(wrapper.find('.modal').exists()).toBe(true)
  })

  it('submit calls saveBudget with correct data', async () => {
    mockSaveBudget.mockResolvedValue(undefined)
    const wrapper = mount(BudgetsView)
    await flushPromises()

    // Open form
    await wrapper.find('.btn-primary').trigger('click')

    // Fill in form
    await wrapper.find('select[name="category_id"]').setValue(1)
    await wrapper.find('input[name="limit_amount"]').setValue('300')

    // Submit
    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(mockSaveBudget).toHaveBeenCalledWith({
      category_id: 1,
      month: 3,
      year: 2026,
      limit_amount: 300,
    })
  })
})
