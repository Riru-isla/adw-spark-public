import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { createRouter, createWebHashHistory } from 'vue-router'
import CollectionDetailView from '../CollectionDetailView.vue'
import { useItemsStore } from '@/stores/items'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', component: { template: '<div />' } },
    { path: '/collections', component: { template: '<div />' } },
    { path: '/collections/:id', component: CollectionDetailView },
    { path: '/collections/:id/items/:itemId', component: { template: '<div />' } },
  ],
})

const sampleItems = [
  {
    id: 1,
    collection_id: 1,
    name: 'Pikachu Card',
    condition: 'near_mint',
    estimated_value: 150,
    acquisition_date: '2024-01-15',
    notes: null,
    photos: [],
  },
  {
    id: 2,
    collection_id: 1,
    name: 'Charizard Card',
    condition: 'mint',
    estimated_value: null,
    acquisition_date: null,
    notes: null,
    photos: [{ id: 1, url: 'http://example.com/photo.jpg', filename: 'photo.jpg', content_type: 'image/jpeg' }],
  },
]

async function mountWithRoute(collectionId: string = '1') {
  await router.push(`/collections/${collectionId}`)
  await router.isReady()
  return mount(CollectionDetailView, { global: { plugins: [router] } })
}

describe('CollectionDetailView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    sessionStorage.clear()
  })

  it('calls fetchItems with the correct collection ID from route params', async () => {
    const store = useItemsStore()
    store.fetchItems = vi.fn()
    store.items = []
    store.loading = false
    store.error = null

    await mountWithRoute('42')

    expect(store.fetchItems).toHaveBeenCalledWith('42')
  })

  it('renders item cards with name, condition, and value when items are present', async () => {
    const store = useItemsStore()
    store.fetchItems = vi.fn()
    store.items = sampleItems
    store.loading = false
    store.error = null

    const wrapper = await mountWithRoute('1')

    expect(wrapper.text()).toContain('Pikachu Card')
    expect(wrapper.text()).toContain('Near Mint')
    expect(wrapper.text()).toContain('$150.00')
    expect(wrapper.text()).toContain('Charizard Card')
    expect(wrapper.text()).toContain('Mint')
    expect(wrapper.text()).toContain('—')
  })

  it('shows empty state when items array is empty', async () => {
    const store = useItemsStore()
    store.fetchItems = vi.fn()
    store.items = []
    store.loading = false
    store.error = null

    const wrapper = await mountWithRoute('1')

    expect(wrapper.text()).toContain('No items in this collection yet')
  })

  it('shows loading state while fetching', async () => {
    const store = useItemsStore()
    store.fetchItems = vi.fn()
    store.loading = true
    store.error = null

    const wrapper = await mountWithRoute('1')

    expect(wrapper.text()).toContain('Loading')
  })

  it('renders RouterLink to item detail for each item card', async () => {
    const store = useItemsStore()
    store.fetchItems = vi.fn()
    store.items = [
      {
        id: 5,
        collection_id: 3,
        name: 'Test Item',
        condition: 'good',
        estimated_value: 10,
        acquisition_date: null,
        notes: null,
        photos: [],
      },
    ]
    store.loading = false
    store.error = null

    const wrapper = await mountWithRoute('3')

    const links = wrapper.findAllComponents({ name: 'RouterLink' })
    const itemLink = links.find((l) => l.props('to') === '/collections/3/items/5')
    expect(itemLink).toBeTruthy()
  })

  it('renders Grid and List toggle buttons', async () => {
    const store = useItemsStore()
    store.fetchItems = vi.fn()
    store.items = []
    store.loading = false
    store.error = null

    const wrapper = await mountWithRoute('1')

    const buttons = wrapper.findAll('.view-btn')
    expect(buttons).toHaveLength(2)
    expect(buttons[0].text()).toBe('Grid')
    expect(buttons[1].text()).toBe('List')
  })

  it('defaults to grid view — .item-cards present, table absent', async () => {
    const store = useItemsStore()
    store.fetchItems = vi.fn()
    store.items = sampleItems
    store.loading = false
    store.error = null

    const wrapper = await mountWithRoute('1')

    expect(wrapper.find('.item-cards').exists()).toBe(true)
    expect(wrapper.find('table').exists()).toBe(false)
  })

  it('clicking List button shows table and hides grid', async () => {
    const store = useItemsStore()
    store.fetchItems = vi.fn()
    store.items = sampleItems
    store.loading = false
    store.error = null

    const wrapper = await mountWithRoute('1')

    const listBtn = wrapper.findAll('.view-btn').find((b) => b.text() === 'List')!
    await listBtn.trigger('click')

    expect(wrapper.find('table').exists()).toBe(true)
    expect(wrapper.find('.item-cards').exists()).toBe(false)
  })

  it('clicking Grid button restores grid and hides table', async () => {
    const store = useItemsStore()
    store.fetchItems = vi.fn()
    store.items = sampleItems
    store.loading = false
    store.error = null

    const wrapper = await mountWithRoute('1')

    const [gridBtn, listBtn] = wrapper.findAll('.view-btn')
    await listBtn.trigger('click')
    await gridBtn.trigger('click')

    expect(wrapper.find('.item-cards').exists()).toBe(true)
    expect(wrapper.find('table').exists()).toBe(false)
  })

  it('writes to sessionStorage when view mode changes', async () => {
    const store = useItemsStore()
    store.fetchItems = vi.fn()
    store.items = sampleItems
    store.loading = false
    store.error = null

    const wrapper = await mountWithRoute('1')

    const listBtn = wrapper.findAll('.view-btn').find((b) => b.text() === 'List')!
    await listBtn.trigger('click')

    expect(sessionStorage.getItem('itemViewMode')).toBe('list')

    const gridBtn = wrapper.findAll('.view-btn').find((b) => b.text() === 'Grid')!
    await gridBtn.trigger('click')

    expect(sessionStorage.getItem('itemViewMode')).toBe('grid')
  })

  it('restores view mode from sessionStorage on mount', async () => {
    sessionStorage.setItem('itemViewMode', 'list')

    const store = useItemsStore()
    store.fetchItems = vi.fn()
    store.items = sampleItems
    store.loading = false
    store.error = null

    const wrapper = await mountWithRoute('1')

    expect(wrapper.find('table').exists()).toBe(true)
    expect(wrapper.find('.item-cards').exists()).toBe(false)
  })

  it('list view table contains item name, condition, value, and acquired columns', async () => {
    const store = useItemsStore()
    store.fetchItems = vi.fn()
    store.items = sampleItems
    store.loading = false
    store.error = null

    const wrapper = await mountWithRoute('1')

    const listBtn = wrapper.findAll('.view-btn').find((b) => b.text() === 'List')!
    await listBtn.trigger('click')

    const tableText = wrapper.find('table').text()
    expect(tableText).toContain('Name')
    expect(tableText).toContain('Condition')
    expect(tableText).toContain('Value')
    expect(tableText).toContain('Acquired')
    expect(tableText).toContain('Pikachu Card')
    expect(tableText).toContain('Near Mint')
    expect(tableText).toContain('$150.00')
  })
})
