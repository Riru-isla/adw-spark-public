import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import CategoriesView from './CategoriesView.vue'

vi.mock('@/stores/categories', () => ({
  useCategoriesStore: vi.fn(),
}))

import { useCategoriesStore } from '@/stores/categories'

const mockFetchCategories = vi.fn()

function makeCategoryStore(overrides: object = {}) {
  return {
    categories: [],
    loading: false,
    error: null,
    fetchCategories: mockFetchCategories,
    addCategory: vi.fn(),
    editCategory: vi.fn(),
    removeCategory: vi.fn(),
    ...overrides,
  }
}

const globalConfig = {
  stubs: {
    CategoryForm: { name: 'CategoryForm', template: '<div />' },
  },
}

beforeEach(() => {
  setActivePinia(createPinia())
  vi.clearAllMocks()
  ;(useCategoriesStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue(makeCategoryStore())
})

describe('CategoriesView', () => {
  it('renders "No categories yet." when categories is empty and not loading', async () => {
    const wrapper = mount(CategoriesView, { global: globalConfig })
    await flushPromises()
    const msg = wrapper.find('.state-msg')
    expect(msg.exists()).toBe(true)
    expect(msg.text()).toBe('No categories yet.')
  })

  it('renders "Loading…" when loading is true', async () => {
    ;(useCategoriesStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue(
      makeCategoryStore({ loading: true }),
    )
    const wrapper = mount(CategoriesView, { global: globalConfig })
    await flushPromises()
    const msg = wrapper.find('.state-msg')
    expect(msg.exists()).toBe(true)
    expect(msg.text()).toBe('Loading…')
  })
})
