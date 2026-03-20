import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import CategoriesView from '../../views/CategoriesView.vue'

// Stub vanilla-colorful custom element
if (!customElements.get('hex-color-picker')) {
  customElements.define(
    'hex-color-picker',
    class extends HTMLElement {
      static get observedAttributes() {
        return ['color']
      }
    },
  )
}

const mockCategories = [
  { id: 1, name: 'Food', color: '#ff0000', icon: 'food' },
  { id: 2, name: 'Transport', color: '#0000ff', icon: 'transport' },
]

vi.mock('@/stores/categories', () => ({
  useCategoriesStore: vi.fn(),
}))

import { useCategoriesStore } from '@/stores/categories'

const mockRemoveCategory = vi.fn()
const mockAddCategory = vi.fn()
const mockEditCategory = vi.fn()
const mockFetchCategories = vi.fn()

function makeMockStore(overrides: object = {}) {
  return {
    categories: mockCategories,
    loading: false,
    error: null,
    fetchCategories: mockFetchCategories,
    addCategory: mockAddCategory,
    editCategory: mockEditCategory,
    removeCategory: mockRemoveCategory,
    ...overrides,
  }
}

beforeEach(() => {
  setActivePinia(createPinia())
  vi.clearAllMocks()
  ;(useCategoriesStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue(makeMockStore())
})

describe('CategoriesView', () => {
  it('renders the category list when store has categories', async () => {
    const wrapper = mount(CategoriesView)
    await flushPromises()
    expect(wrapper.text()).toContain('Food')
    expect(wrapper.text()).toContain('Transport')
  })

  it('shows Add Category button and opens the form on click', async () => {
    const wrapper = mount(CategoriesView)
    const addBtn = wrapper.find('button.btn-primary')
    expect(addBtn.exists()).toBe(true)
    expect(addBtn.text()).toBe('Add Category')
    await addBtn.trigger('click')
    expect(wrapper.find('.modal').exists()).toBe(true)
  })

  it('calls removeCategory on delete confirmation', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    const wrapper = mount(CategoriesView)
    await flushPromises()
    const deleteButtons = wrapper.findAll('.btn-danger')
    expect(deleteButtons.length).toBeGreaterThan(0)
    await deleteButtons[0]!.trigger('click')
    expect(mockRemoveCategory).toHaveBeenCalledWith(mockCategories[0]!.id)
  })
})
