import { ref } from 'vue'
import { defineStore } from 'pinia'
import { getDashboard } from '@/services/api'

export interface RecentItemPhoto {
  id: number
  url: string
  filename: string
  content_type: string
}

export interface RecentItem {
  id: number
  name: string
  collection_name: string
  photos: RecentItemPhoto[]
}

export const useDashboardStore = defineStore('dashboard', () => {
  const totalCollections = ref(0)
  const totalItems = ref(0)
  const totalEstimatedValue = ref(0)
  const valueByCondition = ref<Record<string, number>>({})
  const recentlyAddedItems = ref<RecentItem[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchDashboard() {
    loading.value = true
    error.value = null
    try {
      const data = await getDashboard()
      totalCollections.value = data.total_collections
      totalItems.value = data.total_items
      totalEstimatedValue.value = data.total_estimated_value
      valueByCondition.value = data.value_by_condition ?? {}
      recentlyAddedItems.value = data.recently_added_items
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to load dashboard'
    } finally {
      loading.value = false
    }
  }

  return {
    totalCollections,
    totalItems,
    totalEstimatedValue,
    valueByCondition,
    recentlyAddedItems,
    loading,
    error,
    fetchDashboard,
  }
})
