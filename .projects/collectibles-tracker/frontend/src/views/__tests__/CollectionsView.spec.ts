import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { createRouter, createWebHashHistory } from 'vue-router'
import CollectionsView from '../CollectionsView.vue'
import { useCollectionsStore } from '@/stores/collections'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [{ path: '/', component: CollectionsView }],
})

describe('CollectionsView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('renders collections as cards with name, item count, and total value', async () => {
    const store = useCollectionsStore()
    store.fetchCollections = vi.fn()
    store.collections = [
      { id: 1, name: 'Stamps', category: 'Philately', description: null, item_count: 10, total_value: 500 },
      { id: 2, name: 'Coins', category: null, description: null, item_count: 5, total_value: 250.75 },
    ]
    store.loading = false
    store.error = null

    const wrapper = mount(CollectionsView, { global: { plugins: [router] } })

    expect(wrapper.text()).toContain('Stamps')
    expect(wrapper.text()).toContain('10 items')
    expect(wrapper.text()).toContain('$500.00')
    expect(wrapper.text()).toContain('Coins')
    expect(wrapper.text()).toContain('5 items')
    expect(wrapper.text()).toContain('$250.75')
  })

  it('shows loading indicator when loading', () => {
    const store = useCollectionsStore()
    store.fetchCollections = vi.fn()
    store.loading = true
    store.error = null

    const wrapper = mount(CollectionsView, { global: { plugins: [router] } })

    expect(wrapper.text()).toContain('Loading')
  })

  it('shows error message when there is an error', () => {
    const store = useCollectionsStore()
    store.fetchCollections = vi.fn()
    store.loading = false
    store.error = 'Failed to load collections'

    const wrapper = mount(CollectionsView, { global: { plugins: [router] } })

    expect(wrapper.text()).toContain('Failed to load collections')
  })

  it('opens modal when "New Collection" is clicked', async () => {
    const store = useCollectionsStore()
    store.fetchCollections = vi.fn()
    store.collections = []
    store.loading = false
    store.error = null

    const wrapper = mount(CollectionsView, { global: { plugins: [router] } })

    const btn = wrapper.find('button.btn-primary')
    await btn.trigger('click')

    expect(wrapper.find('.modal-backdrop').exists()).toBe(true)
  })

  it('calls deleteCollection after confirm on Delete click', async () => {
    const store = useCollectionsStore()
    store.fetchCollections = vi.fn()
    store.deleteCollection = vi.fn().mockResolvedValue(undefined)
    store.collections = [
      { id: 1, name: 'Stamps', category: null, description: null, item_count: 3, total_value: 100 },
    ]
    store.loading = false
    store.error = null

    vi.stubGlobal('confirm', vi.fn().mockReturnValue(true))

    const wrapper = mount(CollectionsView, { global: { plugins: [router] } })

    const deleteBtn = wrapper.find('.btn-danger')
    await deleteBtn.trigger('click')

    expect(store.deleteCollection).toHaveBeenCalledWith(1)

    vi.unstubAllGlobals()
  })
})
