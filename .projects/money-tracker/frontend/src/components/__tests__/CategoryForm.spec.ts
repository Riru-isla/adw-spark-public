import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import CategoryForm from '../CategoryForm.vue'

// vanilla-colorful uses custom elements — stub it for jsdom
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

beforeEach(() => {
  setActivePinia(createPinia())
})

describe('CategoryForm', () => {
  it('renders name input, color picker, and icon input', () => {
    const wrapper = mount(CategoryForm)
    expect(wrapper.find('input#cat-name').exists()).toBe(true)
    expect(wrapper.find('hex-color-picker').exists()).toBe(true)
    expect(wrapper.find('input#cat-icon').exists()).toBe(true)
  })

  it('emits submit with form data when submitted with valid name', async () => {
    const wrapper = mount(CategoryForm)
    await wrapper.find('input#cat-name').setValue('Groceries')
    await wrapper.find('form').trigger('submit')
    expect(wrapper.emitted('submit')).toBeTruthy()
    const payload = wrapper.emitted('submit')![0]![0] as { name: string; color: string; icon: string }
    expect(payload.name).toBe('Groceries')
    expect(typeof payload.color).toBe('string')
  })

  it('shows validation error if name is empty on submit', async () => {
    const wrapper = mount(CategoryForm)
    await wrapper.find('form').trigger('submit')
    expect(wrapper.emitted('submit')).toBeFalsy()
    expect(wrapper.text()).toContain('Name is required')
  })

  it('pre-fills fields in edit mode when category prop is provided', () => {
    const category = { id: 1, name: 'Food', color: '#ff0000', icon: 'food' }
    const wrapper = mount(CategoryForm, { props: { category } })
    const nameInput = wrapper.find('input#cat-name').element as HTMLInputElement
    const iconInput = wrapper.find('input#cat-icon').element as HTMLInputElement
    expect(nameInput.value).toBe('Food')
    expect(iconInput.value).toBe('food')
  })
})
