import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { createRouter, createWebHashHistory } from 'vue-router'
import SearchView from '../SearchView.vue'
import { useItemsStore } from '@/stores/items'
import { useCollectionsStore } from '@/stores/collections'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [{ path: '/', component: SearchView }],
})

const SearchFilterPanelStub = {
  name: 'SearchFilterPanel',
  emits: ['search'],
  template: '<div class="search-filter-stub" />',
}

const fixtureItems = [
  {
    id: 1,
    collection_id: 1,
    name: 'Foil Charizard',
    condition: 'mint',
    estimated_value: 250,
    photos: [],
    acquisition_date: null,
    notes: null,
  },
  {
    id: 2,
    collection_id: 1,
    name: 'Base Pikachu',
    condition: 'good',
    estimated_value: 50,
    photos: [],
    acquisition_date: null,
    notes: null,
  },
]

describe('SearchView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('renders both item names after a search returns results', async () => {
    const itemsStore = useItemsStore()
    const collectionsStore = useCollectionsStore()

    itemsStore.searchItems = vi.fn().mockImplementation(async () => {
      itemsStore.searchResults = fixtureItems
    })
    itemsStore.searchResults = fixtureItems
    collectionsStore.fetchCollections = vi.fn()
    collectionsStore.collections = []

    const wrapper = mount(SearchView, {
      global: {
        plugins: [router],
        stubs: { SearchFilterPanel: SearchFilterPanelStub },
      },
    })

    await wrapper.findComponent(SearchFilterPanelStub).vm.$emit('search', { query: 'card' })
    await wrapper.vm.$nextTick()

    expect(wrapper.text()).toContain('Foil Charizard')
    expect(wrapper.text()).toContain('Base Pikachu')
  })

  it('calls searchItems with the typed query', async () => {
    const itemsStore = useItemsStore()
    const collectionsStore = useCollectionsStore()

    itemsStore.searchItems = vi.fn().mockResolvedValue(undefined)
    itemsStore.searchResults = []
    collectionsStore.fetchCollections = vi.fn()
    collectionsStore.collections = []

    const wrapper = mount(SearchView, {
      global: {
        plugins: [router],
        stubs: { SearchFilterPanel: SearchFilterPanelStub },
      },
    })

    await wrapper.findComponent(SearchFilterPanelStub).vm.$emit('search', { query: 'charizard' })
    await wrapper.vm.$nextTick()

    expect(itemsStore.searchItems).toHaveBeenCalledWith({ query: 'charizard' })
  })
})
