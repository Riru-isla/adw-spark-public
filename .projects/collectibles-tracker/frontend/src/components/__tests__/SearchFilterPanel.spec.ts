import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import SearchFilterPanel from '../SearchFilterPanel.vue'
import { useCollectionsStore } from '@/stores/collections'

describe('SearchFilterPanel', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('emits search event after debounce when query input changes', async () => {
    const wrapper = mount(SearchFilterPanel)

    await wrapper.find('[data-testid="search-query"]').setValue('batman')
    // Before debounce fires, no search event yet
    expect(wrapper.emitted('search') ?? []).toHaveLength(0)

    vi.advanceTimersByTime(300)
    await wrapper.vm.$nextTick()
    expect(wrapper.emitted('search')).toHaveLength(1)
  })

  it('emits search with query in params', async () => {
    const wrapper = mount(SearchFilterPanel)
    const searches: unknown[] = []
    wrapper.vm.$on?.('search', (p: unknown) => searches.push(p))

    await wrapper.find('[data-testid="search-query"]').setValue('coin')
    vi.advanceTimersByTime(300)
    await wrapper.vm.$nextTick()

    const emitted = wrapper.emitted('search') as unknown[][]
    expect(emitted).toBeTruthy()
    const last = emitted[emitted.length - 1][0] as Record<string, unknown>
    expect(last.query).toBe('coin')
  })

  it('emits search with condition param when condition is selected', async () => {
    const wrapper = mount(SearchFilterPanel)

    await wrapper.find('[data-testid="search-condition"]').setValue('mint')
    vi.advanceTimersByTime(300)
    await wrapper.vm.$nextTick()

    const emitted = wrapper.emitted('search') as unknown[][]
    const last = emitted[emitted.length - 1][0] as Record<string, unknown>
    expect(last.condition).toBe('mint')
  })

  it('emits search with value_min and value_max params', async () => {
    const wrapper = mount(SearchFilterPanel)

    await wrapper.find('[data-testid="search-value-min"]').setValue('10')
    await wrapper.find('[data-testid="search-value-max"]').setValue('100')
    vi.advanceTimersByTime(300)
    await wrapper.vm.$nextTick()

    const emitted = wrapper.emitted('search') as unknown[][]
    const last = emitted[emitted.length - 1][0] as Record<string, unknown>
    // number inputs return numbers in Vue 3
    expect(Number(last.value_min)).toBe(10)
    expect(Number(last.value_max)).toBe(100)
  })

  it('populates collection dropdown from collections store', async () => {
    const store = useCollectionsStore()
    store.collections = [
      { id: 1, name: 'Comics', category: null, description: null, item_count: 0, total_value: 0 },
      { id: 2, name: 'Stamps', category: null, description: null, item_count: 0, total_value: 0 },
    ]
    const wrapper = mount(SearchFilterPanel)

    const options = wrapper.findAll('[data-testid="search-collection"] option')
    expect(options.length).toBe(3) // "All Collections" + 2 collections
    expect(options[1].text()).toBe('Comics')
    expect(options[2].text()).toBe('Stamps')
  })

  it('clear button resets all fields and emits search with empty params', async () => {
    const wrapper = mount(SearchFilterPanel)

    await wrapper.find('[data-testid="search-query"]').setValue('test')
    await wrapper.find('[data-testid="search-condition"]').setValue('mint')
    vi.advanceTimersByTime(300)
    await wrapper.vm.$nextTick()

    expect(wrapper.find('.btn-clear').exists()).toBe(true)
    await wrapper.find('.btn-clear').trigger('click')

    const emitted = wrapper.emitted('search') as unknown[][]
    const last = emitted[emitted.length - 1][0] as Record<string, unknown>
    expect(last).toEqual({})

    expect((wrapper.find('[data-testid="search-query"]').element as HTMLInputElement).value).toBe('')
    expect((wrapper.find('[data-testid="search-condition"]').element as HTMLSelectElement).value).toBe('')
  })

  it('shows active filter count badge when filters are applied', async () => {
    const wrapper = mount(SearchFilterPanel)

    expect(wrapper.find('.filter-badge').exists()).toBe(false)

    await wrapper.find('[data-testid="search-query"]').setValue('foo')
    await wrapper.find('[data-testid="search-condition"]').setValue('good')
    vi.advanceTimersByTime(300)
    await wrapper.vm.$nextTick()

    expect(wrapper.find('.filter-badge').text()).toBe('2')
  })
})
