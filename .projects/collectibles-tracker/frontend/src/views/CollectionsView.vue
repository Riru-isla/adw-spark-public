<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import { useCollectionsStore } from '@/stores/collections'
import type { Collection } from '@/stores/collections'
import CollectionModal from '@/components/CollectionModal.vue'

const store = useCollectionsStore()

const showModal = ref(false)
const selectedCollection = ref<Collection | null>(null)

onMounted(() => {
  store.fetchCollections()
})

function formatCurrency(value: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value)
}

function openCreate() {
  selectedCollection.value = null
  showModal.value = true
}

function openEdit(collection: Collection) {
  selectedCollection.value = collection
  showModal.value = true
}

function closeModal() {
  showModal.value = false
  selectedCollection.value = null
}

async function handleSaved() {
  await store.fetchCollections()
  closeModal()
}

async function handleDelete(collection: Collection) {
  if (window.confirm(`Delete "${collection.name}"? This cannot be undone.`)) {
    await store.deleteCollection(collection.id)
  }
}
</script>

<template>
  <div class="collections">
    <div class="page-header">
      <h1 class="page-title">Collections</h1>
      <button class="btn-primary" @click="openCreate">New Collection</button>
    </div>

    <div v-if="store.loading" class="loading">Loading...</div>

    <div v-else-if="store.error" class="error">{{ store.error }}</div>

    <template v-else>
      <div v-if="store.collections.length === 0" class="empty">No collections yet.</div>
      <div class="collection-cards">
        <div
          v-for="collection in store.collections"
          :key="collection.id"
          class="collection-card"
        >
          <RouterLink :to="`/collections/${collection.id}`" class="card-body card-link">
            <div class="card-name">{{ collection.name }}</div>
            <div class="card-category">{{ collection.category || 'Uncategorized' }}</div>
            <div class="card-stats">
              <span>{{ collection.item_count }} items</span>
              <span class="card-value">{{ formatCurrency(collection.total_value) }}</span>
            </div>
          </RouterLink>
          <div class="card-actions">
            <button class="btn-action" @click.stop="openEdit(collection)">Edit</button>
            <button class="btn-action btn-danger" @click.stop="handleDelete(collection)">Delete</button>
          </div>
        </div>
      </div>
    </template>

    <CollectionModal
      :show="showModal"
      :collection="selectedCollection"
      @close="closeModal"
      @saved="handleSaved"
    />
  </div>
</template>

<style scoped>
.collections {
  max-width: 1000px;
}

.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1.5rem;
}

.page-title {
  font-size: 1.75rem;
  font-weight: 700;
  color: #1e1e2e;
}

.loading,
.error {
  padding: 1rem;
  border-radius: 8px;
}

.loading {
  color: #666;
}

.error {
  color: #d20f39;
  background: #fff0f0;
}

.empty {
  color: #888;
}

.collection-cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 1rem;
}

.collection-card {
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.card-body {
  padding: 1.25rem;
  flex: 1;
}

.card-link {
  text-decoration: none;
  color: inherit;
  display: block;
}

.card-link:hover .card-name {
  color: #1e66f5;
}

.card-name {
  font-size: 1rem;
  font-weight: 700;
  color: #1e1e2e;
  margin-bottom: 0.25rem;
}

.card-category {
  font-size: 0.8rem;
  color: #888;
  margin-bottom: 0.75rem;
}

.card-stats {
  display: flex;
  justify-content: space-between;
  font-size: 0.85rem;
  color: #555;
}

.card-value {
  font-weight: 600;
  color: #1e1e2e;
}

.card-actions {
  display: flex;
  gap: 0.5rem;
  padding: 0.75rem 1.25rem;
  border-top: 1px solid #f0f0f0;
}

.btn-primary {
  background: #1e66f5;
  color: #fff;
  border: none;
  border-radius: 6px;
  padding: 0.5rem 1.25rem;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
}

.btn-action {
  background: #eee;
  color: #333;
  border: none;
  border-radius: 6px;
  padding: 0.35rem 0.85rem;
  font-size: 0.8rem;
  cursor: pointer;
}

.btn-danger {
  background: #fff0f0;
  color: #d20f39;
}
</style>
