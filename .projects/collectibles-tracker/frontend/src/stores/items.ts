import { ref } from 'vue'
import { defineStore } from 'pinia'
import { getItems, getItem, createItem as apiCreateItem, updateItem as apiUpdateItem, deleteItem as apiDeleteItem, searchItems as apiSearchItems } from '@/services/api'
import type { SearchParams } from '@/services/api'

export interface Photo {
  id: number
  url: string
  filename: string
  content_type: string
}

export interface Item {
  id: number
  collection_id: number
  name: string
  condition: string
  estimated_value: number | null
  acquisition_date: string | null
  notes: string | null
  photos: Photo[]
}

export const useItemsStore = defineStore('items', () => {
  const items = ref<Item[]>([])
  const currentItem = ref<Item | null>(null)
  const searchResults = ref<Item[]>([])
  const searching = ref(false)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchItems(collectionId: number | string) {
    loading.value = true
    error.value = null
    try {
      items.value = await getItems(collectionId)
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to load items'
    } finally {
      loading.value = false
    }
  }

  async function fetchItem(itemId: number | string) {
    loading.value = true
    error.value = null
    try {
      currentItem.value = await getItem(itemId)
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to load item'
    } finally {
      loading.value = false
    }
  }

  async function createItem(collectionId: number | string, formData: FormData): Promise<string[] | null> {
    const response = await apiCreateItem(collectionId, formData)
    if (response.status === 422) {
      const body = await response.json()
      return body.errors ?? body
    }
    if (!response.ok) {
      throw new Error(`Failed to create item: ${response.statusText}`)
    }
    const created: Item = await response.json()
    items.value.push(created)
    return null
  }

  async function updateItem(id: number | string, formData: FormData): Promise<string[] | null> {
    const response = await apiUpdateItem(id, formData)
    if (response.status === 422) {
      const body = await response.json()
      return body.errors ?? body
    }
    if (!response.ok) {
      throw new Error(`Failed to update item: ${response.statusText}`)
    }
    const updated: Item = await response.json()
    const idx = items.value.findIndex((i) => i.id === updated.id)
    if (idx !== -1) items.value[idx] = updated
    if (currentItem.value?.id === updated.id) currentItem.value = updated
    return null
  }

  async function searchItemsAction(params: SearchParams): Promise<void> {
    searching.value = true
    error.value = null
    try {
      searchResults.value = await apiSearchItems(params)
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to search items'
    } finally {
      searching.value = false
    }
  }

  async function deleteItem(id: number | string): Promise<void> {
    await apiDeleteItem(id)
    items.value = items.value.filter((i) => i.id !== Number(id))
    if (currentItem.value?.id === Number(id)) currentItem.value = null
  }

  return {
    items,
    currentItem,
    searchResults,
    searching,
    loading,
    error,
    fetchItems,
    fetchItem,
    createItem,
    updateItem,
    deleteItem,
    searchItems: searchItemsAction,
  }
})
