import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import CollectionModal from '../CollectionModal.vue'
import { useCollectionsStore } from '@/stores/collections'

describe('CollectionModal', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('renders in create mode with empty form when no collection prop', () => {
    const wrapper = mount(CollectionModal, {
      props: { show: true },
    })

    expect(wrapper.text()).toContain('New Collection')
    expect((wrapper.find('#name').element as HTMLInputElement).value).toBe('')
    expect((wrapper.find('#category').element as HTMLInputElement).value).toBe('')
  })

  it('renders in edit mode with pre-populated form when collection prop is passed', () => {
    const collection = { id: 1, name: 'Stamps', category: 'Philately', description: 'My stamps', item_count: 5, total_value: 100 }

    const wrapper = mount(CollectionModal, {
      props: { show: true, collection },
    })

    expect(wrapper.text()).toContain('Edit Collection')
    expect((wrapper.find('#name').element as HTMLInputElement).value).toBe('Stamps')
    expect((wrapper.find('#category').element as HTMLInputElement).value).toBe('Philately')
  })

  it('emits close when cancel is clicked', async () => {
    const wrapper = mount(CollectionModal, {
      props: { show: true },
    })

    await wrapper.find('.btn-secondary').trigger('click')

    expect(wrapper.emitted('close')).toBeTruthy()
  })

  it('calls store.createCollection on submit in create mode', async () => {
    const store = useCollectionsStore()
    store.createCollection = vi.fn().mockResolvedValue(null)

    const wrapper = mount(CollectionModal, {
      props: { show: true },
    })

    await wrapper.find('#name').setValue('New Stamps')
    await wrapper.find('form').trigger('submit')

    expect(store.createCollection).toHaveBeenCalledWith(
      expect.objectContaining({ name: 'New Stamps' }),
    )
  })

  it('displays error messages when store action returns errors', async () => {
    const store = useCollectionsStore()
    store.createCollection = vi.fn().mockResolvedValue(["Name can't be blank"])

    const wrapper = mount(CollectionModal, {
      props: { show: true },
    })

    await wrapper.find('form').trigger('submit')

    expect(wrapper.text()).toContain("Name can't be blank")
  })
})
