import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import DashboardView from '../DashboardView.vue'

// Mock chart.js to avoid canvas errors in jsdom
vi.mock('chart.js', () => {
  const noop = {}
  return {
    Chart: class { static register() {} },
    ArcElement: noop,
    Tooltip: noop,
    Legend: noop,
    CategoryScale: noop,
    LinearScale: noop,
    PointElement: noop,
    LineElement: noop,
    Title: noop,
    Filler: noop,
    defaults: { font: {} },
  }
})

vi.mock('vue-chartjs', () => ({
  Pie: { name: 'Pie', template: '<div class="pie-chart" />' },
  Line: { name: 'Line', template: '<div class="line-chart" />' },
}))

const mockDashboardFetch = vi.fn()
const mockBudgetsFetch = vi.fn()

const mockDashboardData = {
  category_breakdown: [
    { category: 'Food', color: '#ff6384', spent: 150.0 },
    { category: 'Transport', color: '#36a2eb', spent: 80.0 },
  ],
  monthly_trend: [
    { label: 'Oct', total: 200 },
    { label: 'Nov', total: 320 },
    { label: 'Dec', total: 180 },
    { label: 'Jan', total: 410 },
    { label: 'Feb', total: 290 },
    { label: 'Mar', total: 230 },
  ],
  budget_health: [],
}

const mockBudgetsList = [
  {
    id: 1,
    limit_amount: 300,
    spent_amount: 150,
    remaining_amount: 150,
    category_id: 1,
    month: 3,
    year: 2026,
    category: { id: 1, name: 'Food', color: '#ff6384', icon: '🍕' },
  },
]

// Mutable store state that tests can modify
const dashboardState = {
  data: mockDashboardData as typeof mockDashboardData | null,
  loading: false,
  error: null as string | null,
  fetchData: mockDashboardFetch,
}

const budgetsState = {
  budgets: mockBudgetsList,
  loading: false,
  error: null as string | null,
  month: 3,
  year: 2026,
  fetchBudgets: mockBudgetsFetch,
}

vi.mock('@/stores/dashboard', () => ({
  useDashboardStore: () => dashboardState,
}))

vi.mock('@/stores/budgets', () => ({
  useBudgetsStore: () => budgetsState,
}))

const globalConfig = {
  stubs: {
    SpendingPieChart: { name: 'SpendingPieChart', template: '<div class="stub-pie" />' },
    MonthlyTrendChart: { name: 'MonthlyTrendChart', template: '<div class="stub-line" />' },
  },
}

describe('DashboardView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
    dashboardState.data = mockDashboardData
    dashboardState.loading = false
    budgetsState.budgets = mockBudgetsList
  })

  it('renders three section headings', () => {
    const wrapper = mount(DashboardView, { global: globalConfig })
    expect(wrapper.text()).toContain('Spending This Month')
    expect(wrapper.text()).toContain('Budget Status')
    expect(wrapper.text()).toContain('6-Month Trend')
  })

  it('renders SpendingPieChart when data is present', () => {
    const wrapper = mount(DashboardView, { global: globalConfig })
    expect(wrapper.findComponent({ name: 'SpendingPieChart' }).exists()).toBe(true)
  })

  it('renders MonthlyTrendChart when data is present', () => {
    const wrapper = mount(DashboardView, { global: globalConfig })
    expect(wrapper.findComponent({ name: 'MonthlyTrendChart' }).exists()).toBe(true)
  })

  it('shows loading text and hides charts when loading is true', () => {
    dashboardState.loading = true
    dashboardState.data = null
    const wrapper = mount(DashboardView, { global: globalConfig })
    expect(wrapper.text()).toContain('Loading')
    expect(wrapper.findComponent({ name: 'SpendingPieChart' }).exists()).toBe(false)
    expect(wrapper.findComponent({ name: 'MonthlyTrendChart' }).exists()).toBe(false)
  })

  it('calls fetchData and fetchBudgets on mount', () => {
    mount(DashboardView, { global: globalConfig })
    expect(mockDashboardFetch).toHaveBeenCalledOnce()
    expect(mockBudgetsFetch).toHaveBeenCalledOnce()
  })

  it('renders budget progress row for each budget', () => {
    const wrapper = mount(DashboardView, { global: globalConfig })
    expect(wrapper.text()).toContain('Food')
    expect(wrapper.text()).toContain('$150.00')
  })
})
