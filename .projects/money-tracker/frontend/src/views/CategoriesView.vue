<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useCategoriesStore } from '@/stores/categories'
import CategoryForm from '@/components/CategoryForm.vue'
import type { Category, CategoryData } from '@/api/index'

const store = useCategoriesStore()

const showForm = ref(false)
const editingCategory = ref<Category | undefined>(undefined)

onMounted(() => {
  store.fetchCategories()
})

function openAdd() {
  editingCategory.value = undefined
  showForm.value = true
}

function openEdit(cat: Category) {
  editingCategory.value = cat
  showForm.value = true
}

function closeForm() {
  showForm.value = false
  editingCategory.value = undefined
}

async function handleSubmit(data: CategoryData) {
  if (editingCategory.value) {
    await store.editCategory(editingCategory.value.id, data)
  } else {
    await store.addCategory(data)
  }
  closeForm()
}

async function handleDelete(cat: Category) {
  if (window.confirm(`Delete category "${cat.name}"?`)) {
    await store.removeCategory(cat.id)
  }
}
</script>

<template>
  <div class="categories-page">
    <div class="page-header">
      <h1>Categories</h1>
      <button class="btn-primary" @click="openAdd">Add Category</button>
    </div>

    <div v-if="store.loading" class="state-msg">Loading…</div>
    <div v-else-if="store.error" class="state-msg error">{{ store.error }}</div>
    <div v-else-if="store.categories.length === 0" class="state-msg">No categories yet.</div>

    <div v-else class="category-grid">
      <div v-for="cat in store.categories" :key="cat.id" class="category-card">
        <span class="color-dot" :style="{ background: cat.color }" />
        <div class="card-info">
          <span class="cat-name">{{ cat.name }}</span>
          <span class="cat-icon">{{ cat.icon }}</span>
        </div>
        <div class="card-actions">
          <button class="btn-icon" title="Edit" @click="openEdit(cat)">&#9998;</button>
          <button class="btn-icon btn-danger" title="Delete" @click="handleDelete(cat)">&#128465;</button>
        </div>
      </div>
    </div>

    <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
      <div class="modal">
        <h2>{{ editingCategory ? 'Edit Category' : 'New Category' }}</h2>
        <CategoryForm :category="editingCategory" @submit="handleSubmit" @cancel="closeForm" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.categories-page {
  max-width: 800px;
}

.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1.5rem;
}

.page-header h1 {
  font-size: 1.5rem;
  font-weight: 600;
  color: var(--color-heading);
}

.state-msg {
  color: var(--color-text);
  padding: 1rem 0;
}

.state-msg.error {
  color: #e53e3e;
}

.category-grid {
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}

.category-card {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  background: var(--color-background-soft);
  border: 1px solid var(--color-border);
  border-radius: 8px;
}

.color-dot {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  flex-shrink: 0;
}

.card-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.1rem;
}

.cat-name {
  font-weight: 500;
  color: var(--color-heading);
}

.cat-icon {
  font-size: 0.8rem;
  color: var(--color-text);
  opacity: 0.7;
}

.card-actions {
  display: flex;
  gap: 0.4rem;
}

.btn-icon {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 1rem;
  padding: 0.2rem 0.4rem;
  border-radius: 4px;
  color: var(--color-text);
}

.btn-icon:hover {
  background: var(--color-background-mute);
}

.btn-danger {
  color: #e53e3e;
}

/* Modal */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}

.modal {
  background: var(--color-background);
  border-radius: 10px;
  padding: 1.75rem;
  width: 420px;
  max-width: 90vw;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.18);
}

.modal h2 {
  font-size: 1.1rem;
  font-weight: 600;
  color: var(--color-heading);
  margin-bottom: 1.25rem;
}

@media (max-width: 640px) {
  .categories-page {
    max-width: 100%;
  }
}
</style>
