import { ref } from 'vue'
import { defineStore } from 'pinia'
import {
  getCategories,
  createCategory,
  updateCategory,
  deleteCategory,
  type Category,
  type CategoryData,
} from '@/api/index'

export const useCategoriesStore = defineStore('categories', () => {
  const categories = ref<Category[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchCategories() {
    loading.value = true
    error.value = null
    try {
      categories.value = await getCategories()
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to load categories'
    } finally {
      loading.value = false
    }
  }

  async function addCategory(data: CategoryData) {
    const created = await createCategory(data)
    categories.value.push(created)
  }

  async function editCategory(id: number, data: Partial<CategoryData>) {
    const updated = await updateCategory(id, data)
    const idx = categories.value.findIndex((c) => c.id === id)
    if (idx !== -1) categories.value[idx] = updated
  }

  async function removeCategory(id: number) {
    await deleteCategory(id)
    categories.value = categories.value.filter((c) => c.id !== id)
  }

  return { categories, loading, error, fetchCategories, addCategory, editCategory, removeCategory }
})
