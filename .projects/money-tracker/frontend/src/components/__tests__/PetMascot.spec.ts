import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import PetMascot from '../PetMascot.vue'

describe('PetMascot', () => {
  it('applies mood-happy class and shows correct caption for happy mood', () => {
    const wrapper = mount(PetMascot, { props: { mood: 'happy' } })
    expect(wrapper.classes()).toContain('mood-happy')
    expect(wrapper.text()).toContain('All good!')
  })

  it('applies mood-worried class and shows correct caption for worried mood', () => {
    const wrapper = mount(PetMascot, { props: { mood: 'worried' } })
    expect(wrapper.classes()).toContain('mood-worried')
    expect(wrapper.text()).toContain('Watch out!')
  })

  it('applies mood-sad class and shows correct caption for sad mood', () => {
    const wrapper = mount(PetMascot, { props: { mood: 'sad' } })
    expect(wrapper.classes()).toContain('mood-sad')
    expect(wrapper.text()).toContain('Over budget!')
  })
})
