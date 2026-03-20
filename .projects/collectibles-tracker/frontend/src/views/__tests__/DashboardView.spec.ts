import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { createRouter, createWebHashHistory } from 'vue-router'
import DashboardView from '../DashboardView.vue'
import { useDashboardStore } from '@/stores/dashboard'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [{ path: '/', component: DashboardView }],
})

describe('DashboardView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('renders stat cards with fixture data', async () => {
    const store = useDashboardStore()
    store.fetchDashboard = vi.fn()
    store.totalCollections = 5
    store.totalItems = 42
    store.totalEstimatedValue = 1234.56
    store.recentlyAddedItems = []
    store.loading = false
    store.error = null

    const wrapper = mount(DashboardView, {
      global: { plugins: [router] },
    })

    expect(wrapper.text()).toContain('5')
    expect(wrapper.text()).toContain('42')
    expect(wrapper.text()).toContain('$1,234.56')
  })

  it('renders recently added item cards with item name', async () => {
    const store = useDashboardStore()
    store.fetchDashboard = vi.fn()
    store.totalCollections = 1
    store.totalItems = 1
    store.totalEstimatedValue = 0
    store.recentlyAddedItems = [
      { id: 1, name: 'Vintage Watch', collection_name: 'Watches', photos: [] },
    ]
    store.loading = false
    store.error = null

    const wrapper = mount(DashboardView, {
      global: { plugins: [router] },
    })

    expect(wrapper.text()).toContain('Vintage Watch')
  })

  it('renders loading indicator when loading', async () => {
    const store = useDashboardStore()
    store.fetchDashboard = vi.fn()
    store.loading = true
    store.error = null

    const wrapper = mount(DashboardView, {
      global: { plugins: [router] },
    })

    expect(wrapper.text()).toContain('Loading')
  })

  it('calls fetchDashboard on mount', async () => {
    const store = useDashboardStore()
    const fetchSpy = vi.fn()
    store.fetchDashboard = fetchSpy
    store.loading = false
    store.error = null

    mount(DashboardView, {
      global: { plugins: [router] },
    })

    expect(fetchSpy).toHaveBeenCalledOnce()
  })
})
