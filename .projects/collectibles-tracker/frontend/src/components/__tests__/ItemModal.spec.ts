import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import ItemModal from '../ItemModal.vue'
import { useItemsStore } from '@/stores/items'

const mockItem = {
  id: 1,
  collection_id: 10,
  name: 'Green Knight #1',
  condition: 'near_mint',
  estimated_value: 29.99,
  acquisition_date: '2024-01-15',
  notes: 'Great condition',
  photos: [
    { id: 101, url: 'http://example.com/photo1.jpg', filename: 'photo1.jpg', content_type: 'image/jpeg' },
  ],
}

// Stub URL.createObjectURL
globalThis.URL.createObjectURL = vi.fn(() => 'blob:mock-url')
globalThis.URL.revokeObjectURL = vi.fn()

describe('ItemModal', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('renders in create mode: all fields empty, condition defaults to mint, no existing photos', () => {
    const wrapper = mount(ItemModal, {
      props: { show: true, collectionId: 10 },
    })

    expect(wrapper.text()).toContain('New Item')
    expect((wrapper.find('#item-name').element as HTMLInputElement).value).toBe('')
    expect((wrapper.find('#item-condition').element as HTMLSelectElement).value).toBe('mint')
    expect((wrapper.find('#item-estimated-value').element as HTMLInputElement).value).toBe('')
    expect((wrapper.find('#item-acquisition-date').element as HTMLInputElement).value).toBe('')
    expect((wrapper.find('#item-notes').element as HTMLTextAreaElement).value).toBe('')
    expect(wrapper.findAll('.photo-thumb')).toHaveLength(0)
  })

  it('renders in edit mode: fields pre-populated, existing photos displayed', () => {
    const wrapper = mount(ItemModal, {
      props: { show: true, collectionId: 10, item: mockItem },
    })

    expect(wrapper.text()).toContain('Edit Item')
    expect((wrapper.find('#item-name').element as HTMLInputElement).value).toBe('Green Knight #1')
    expect((wrapper.find('#item-condition').element as HTMLSelectElement).value).toBe('near_mint')
    expect((wrapper.find('#item-estimated-value').element as HTMLInputElement).value).toBe('29.99')
    expect((wrapper.find('#item-acquisition-date').element as HTMLInputElement).value).toBe('2024-01-15')
    expect((wrapper.find('#item-notes').element as HTMLTextAreaElement).value).toBe('Great condition')
    // Existing photo is shown
    expect(wrapper.findAll('.photo-thumb')).toHaveLength(1)
  })

  it('condition dropdown has all 5 options with correct labels', () => {
    const wrapper = mount(ItemModal, {
      props: { show: true, collectionId: 10 },
    })

    const options = wrapper.findAll('#item-condition option')
    expect(options).toHaveLength(5)

    const labels = options.map((o) => o.text())
    expect(labels).toContain('Mint')
    expect(labels).toContain('Near Mint')
    expect(labels).toContain('Good')
    expect(labels).toContain('Fair')
    expect(labels).toContain('Poor')
  })

  it('file input change triggers thumbnail previews to appear', async () => {
    const wrapper = mount(ItemModal, {
      props: { show: true, collectionId: 10 },
    })

    const file = new File(['x'], 'test.jpg', { type: 'image/jpeg' })
    const input = wrapper.find('input[type="file"]')
    Object.defineProperty(input.element, 'files', {
      value: [file],
      configurable: true,
    })
    await input.trigger('change')

    expect(URL.createObjectURL).toHaveBeenCalledWith(file)
    expect(wrapper.findAll('.photo-thumb--new')).toHaveLength(1)
  })

  it('removing an existing photo removes it from list and adds id to removedPhotoIds', async () => {
    const wrapper = mount(ItemModal, {
      props: { show: true, collectionId: 10, item: mockItem },
    })

    expect(wrapper.findAll('.photo-thumb')).toHaveLength(1)

    const removeBtn = wrapper.find('.remove-photo')
    await removeBtn.trigger('click')

    expect(wrapper.findAll('.photo-thumb')).toHaveLength(0)

    // Check internal state via submitting - mock store and verify FormData
    const store = useItemsStore()
    store.updateItem = vi.fn().mockResolvedValue(null)

    await wrapper.find('form').trigger('submit')

    const formData: FormData = (store.updateItem as ReturnType<typeof vi.fn>).mock.calls[0][1]
    expect(formData.getAll('item[remove_photo_ids][]')).toContain('101')
  })

  it('submit in create mode calls createItem with FormData containing field values', async () => {
    const store = useItemsStore()
    store.createItem = vi.fn().mockResolvedValue(null)

    const wrapper = mount(ItemModal, {
      props: { show: true, collectionId: 10 },
    })

    await wrapper.find('#item-name').setValue('Batman #1')
    await wrapper.find('#item-condition').setValue('good')
    await wrapper.find('form').trigger('submit')

    expect(store.createItem).toHaveBeenCalledWith(
      10,
      expect.any(FormData),
    )

    const formData: FormData = (store.createItem as ReturnType<typeof vi.fn>).mock.calls[0][1]
    expect(formData.get('item[name]')).toBe('Batman #1')
    expect(formData.get('item[condition]')).toBe('good')
  })

  it('submit in edit mode calls updateItem with remove_photo_ids when photos were removed', async () => {
    const store = useItemsStore()
    store.updateItem = vi.fn().mockResolvedValue(null)

    const wrapper = mount(ItemModal, {
      props: { show: true, collectionId: 10, item: mockItem },
    })

    // Remove the existing photo
    await wrapper.find('.remove-photo').trigger('click')
    await wrapper.find('form').trigger('submit')

    expect(store.updateItem).toHaveBeenCalledWith(mockItem.id, expect.any(FormData))

    const formData: FormData = (store.updateItem as ReturnType<typeof vi.fn>).mock.calls[0][1]
    expect(formData.getAll('item[remove_photo_ids][]')).toContain('101')
  })

  it('422 response displays field errors', async () => {
    const store = useItemsStore()
    store.createItem = vi.fn().mockResolvedValue(["Name can't be blank"])

    const wrapper = mount(ItemModal, {
      props: { show: true, collectionId: 10 },
    })

    await wrapper.find('form').trigger('submit')

    expect(wrapper.text()).toContain("Name can't be blank")
  })
})
