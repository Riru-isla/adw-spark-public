import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ValueBreakdown from '../ValueBreakdown.vue'

describe('ValueBreakdown', () => {
  it('renders condition labels and USD-formatted values', () => {
    const wrapper = mount(ValueBreakdown, {
      props: {
        breakdown: { mint: 150.0, near_mint: 75.5, good: 0, fair: 0, poor: 0 },
      },
    })

    expect(wrapper.text()).toContain('Mint')
    expect(wrapper.text()).toContain('$150.00')
    expect(wrapper.text()).toContain('Near Mint')
    expect(wrapper.text()).toContain('$75.50')
  })

  it('hides rows with zero value', () => {
    const wrapper = mount(ValueBreakdown, {
      props: {
        breakdown: { mint: 100.0, near_mint: 0, good: 0, fair: 0, poor: 0 },
      },
    })

    expect(wrapper.text()).toContain('Mint')
    expect(wrapper.text()).not.toContain('Near Mint')
    expect(wrapper.text()).not.toContain('Good')
    expect(wrapper.text()).not.toContain('Fair')
    expect(wrapper.text()).not.toContain('Poor')
  })

  it('shows "No values recorded" when all values are zero', () => {
    const wrapper = mount(ValueBreakdown, {
      props: {
        breakdown: { mint: 0, near_mint: 0, good: 0, fair: 0, poor: 0 },
      },
    })

    expect(wrapper.text()).toContain('No values recorded')
  })

  it('shows "No values recorded" when breakdown is empty', () => {
    const wrapper = mount(ValueBreakdown, {
      props: { breakdown: {} },
    })

    expect(wrapper.text()).toContain('No values recorded')
  })

  it('renders conditions in canonical order (mint first, poor last)', () => {
    const wrapper = mount(ValueBreakdown, {
      props: {
        breakdown: { poor: 10, mint: 200, good: 50, near_mint: 80, fair: 20 },
      },
    })

    const labels = wrapper.findAll('.condition-label').map((el) => el.text())
    expect(labels).toEqual(['Mint', 'Near Mint', 'Good', 'Fair', 'Poor'])
  })
})
