import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { createRouter, createWebHashHistory } from 'vue-router'
import ItemDetailView from '../ItemDetailView.vue'
import { useItemsStore } from '@/stores/items'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', component: { template: '<div />' } },
    { path: '/collections/:id', component: { template: '<div />' } },
    { path: '/collections/:id/items/:itemId', component: ItemDetailView },
  ],
})

async function mountWithRoute(collectionId: string = '1', itemId: string = '2') {
  await router.push(`/collections/${collectionId}/items/${itemId}`)
  await router.isReady()
  return mount(ItemDetailView, { global: { plugins: [router] } })
}

describe('ItemDetailView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('calls fetchItem with the correct item ID from route params', async () => {
    const store = useItemsStore()
    store.fetchItem = vi.fn()
    store.currentItem = null
    store.loading = false
    store.error = null

    await mountWithRoute('1', '99')

    expect(store.fetchItem).toHaveBeenCalledWith('99')
  })

  it('renders item name, condition, value, date, and notes', async () => {
    const store = useItemsStore()
    store.fetchItem = vi.fn()
    store.currentItem = {
      id: 2,
      collection_id: 1,
      name: 'Rare Stamp',
      condition: 'very_fine',
      estimated_value: 299.99,
      acquisition_date: '2024-06-15',
      notes: 'Bought at auction',
      photos: [],
    }
    store.loading = false
    store.error = null

    const wrapper = await mountWithRoute('1', '2')

    expect(wrapper.text()).toContain('Rare Stamp')
    expect(wrapper.text()).toContain('Very Fine')
    expect(wrapper.text()).toContain('$299.99')
    expect(wrapper.text()).toContain('Bought at auction')
  })

  it('renders photo images when photos are present', async () => {
    const store = useItemsStore()
    store.fetchItem = vi.fn()
    store.currentItem = {
      id: 2,
      collection_id: 1,
      name: 'Photo Item',
      condition: 'mint',
      estimated_value: null,
      acquisition_date: null,
      notes: null,
      photos: [
        { id: 1, url: 'http://example.com/photo1.jpg', filename: 'photo1.jpg', content_type: 'image/jpeg' },
        { id: 2, url: 'http://example.com/photo2.jpg', filename: 'photo2.jpg', content_type: 'image/jpeg' },
      ],
    }
    store.loading = false
    store.error = null

    const wrapper = await mountWithRoute('1', '2')

    const images = wrapper.findAll('img.photo-img')
    expect(images).toHaveLength(2)
    expect(images[0].attributes('src')).toBe('http://example.com/photo1.jpg')
    expect(images[1].attributes('src')).toBe('http://example.com/photo2.jpg')
  })

  it('shows placeholder when photos array is empty', async () => {
    const store = useItemsStore()
    store.fetchItem = vi.fn()
    store.currentItem = {
      id: 2,
      collection_id: 1,
      name: 'No Photo Item',
      condition: 'good',
      estimated_value: null,
      acquisition_date: null,
      notes: null,
      photos: [],
    }
    store.loading = false
    store.error = null

    const wrapper = await mountWithRoute('1', '2')

    expect(wrapper.find('.photo-placeholder').exists()).toBe(true)
    expect(wrapper.find('img.photo-img').exists()).toBe(false)
  })

  it('back link points to the correct collection route', async () => {
    const store = useItemsStore()
    store.fetchItem = vi.fn()
    store.currentItem = {
      id: 5,
      collection_id: 7,
      name: 'Some Item',
      condition: 'fair',
      estimated_value: null,
      acquisition_date: null,
      notes: null,
      photos: [],
    }
    store.loading = false
    store.error = null

    const wrapper = await mountWithRoute('7', '5')

    const links = wrapper.findAllComponents({ name: 'RouterLink' })
    const backLink = links.find((l) => l.props('to') === '/collections/7')
    expect(backLink).toBeTruthy()
  })
})
