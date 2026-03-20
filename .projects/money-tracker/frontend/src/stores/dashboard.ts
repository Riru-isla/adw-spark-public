import { ref } from 'vue'
import { defineStore } from 'pinia'
import { fetchDashboard, type DashboardData } from '@/api/index'

export const useDashboardStore = defineStore('dashboard', () => {
  const data = ref<DashboardData | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchData() {
    loading.value = true
    error.value = null
    try {
      data.value = await fetchDashboard()
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to load dashboard'
    } finally {
      loading.value = false
    }
  }

  return { data, loading, error, fetchData }
})
