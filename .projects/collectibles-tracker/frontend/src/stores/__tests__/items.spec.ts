import { describe, it, expect, vi, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useItemsStore } from '../items'
import * as api from '@/services/api'

const mockItems = [
  {
    id: 1,
    collection_id: 1,
    name: 'Batman #1',
    condition: 'mint',
    estimated_value: 100,
    acquisition_date: null,
    notes: null,
    photos: [],
  },
]

describe('useItemsStore — searchItems', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.restoreAllMocks()
  })

  it('calls searchItems API with given params', async () => {
    const spy = vi.spyOn(api, 'searchItems').mockResolvedValue(mockItems)

    const store = useItemsStore()
    await store.searchItems({ query: 'batman', condition: 'mint' })

    expect(spy).toHaveBeenCalledWith({ query: 'batman', condition: 'mint' })
  })

  it('sets searchResults from API response', async () => {
    vi.spyOn(api, 'searchItems').mockResolvedValue(mockItems)

    const store = useItemsStore()
    await store.searchItems({ query: 'batman' })

    expect(store.searchResults).toEqual(mockItems)
  })

  it('sets searching to true while loading, false when done', async () => {
    let resolveSearch!: (v: unknown) => void
    vi.spyOn(api, 'searchItems').mockReturnValue(
      new Promise((res) => { resolveSearch = res })
    )

    const store = useItemsStore()
    const promise = store.searchItems({ query: 'test' })

    expect(store.searching).toBe(true)

    resolveSearch(mockItems)
    await promise

    expect(store.searching).toBe(false)
  })

  it('sets searching to false on API error', async () => {
    vi.spyOn(api, 'searchItems').mockRejectedValue(new Error('Network error'))

    const store = useItemsStore()
    await store.searchItems({})

    expect(store.searching).toBe(false)
    expect(store.error).toBe('Network error')
  })
})
