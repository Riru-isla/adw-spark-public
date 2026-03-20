import { ref } from 'vue'
import { defineStore } from 'pinia'
import { getCollections, getCollection, createCollection, updateCollection, deleteCollection } from '@/services/api'

export interface Collection {
  id: number
  name: string
  category: string | null
  description: string | null
  item_count: number
  total_value: number
  value_by_condition?: Record<string, number> | null
}

export interface CollectionFormData {
  name: string
  category?: string
  description?: string
}

export const useCollectionsStore = defineStore('collections', () => {
  const collections = ref<Collection[]>([])
  const currentCollection = ref<Collection | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchCollections() {
    loading.value = true
    error.value = null
    try {
      collections.value = await getCollections()
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to load collections'
    } finally {
      loading.value = false
    }
  }

  async function fetchCollection(id: number | string) {
    loading.value = true
    error.value = null
    try {
      currentCollection.value = await getCollection(id)
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to load collection'
    } finally {
      loading.value = false
    }
  }

  async function createCollectionAction(data: CollectionFormData): Promise<string[] | null> {
    const response = await createCollection(data)
    if (response.ok) {
      await fetchCollections()
      return null
    } else if (response.status === 422) {
      const body = await response.json()
      return body.errors as string[]
    } else {
      throw new Error(`Failed to create collection: ${response.statusText}`)
    }
  }

  async function updateCollectionAction(id: number, data: CollectionFormData): Promise<string[] | null> {
    const response = await updateCollection(id, data)
    if (response.ok) {
      await fetchCollections()
      return null
    } else if (response.status === 422) {
      const body = await response.json()
      return body.errors as string[]
    } else {
      throw new Error(`Failed to update collection: ${response.statusText}`)
    }
  }

  async function deleteCollectionAction(id: number) {
    await deleteCollection(id)
    await fetchCollections()
  }

  return {
    collections,
    currentCollection,
    loading,
    error,
    fetchCollections,
    fetchCollection,
    createCollection: createCollectionAction,
    updateCollection: updateCollectionAction,
    deleteCollection: deleteCollectionAction,
  }
})
