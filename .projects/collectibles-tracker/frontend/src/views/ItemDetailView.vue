<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute, RouterLink, useRouter } from 'vue-router'
import { useItemsStore } from '@/stores/items'
import ItemModal from '@/components/ItemModal.vue'

const route = useRoute()
const router = useRouter()
const collectionId = route.params.id as string
const itemId = route.params.itemId as string

const itemsStore = useItemsStore()
const showEditModal = ref(false)

onMounted(() => {
  itemsStore.fetchItem(itemId)
})

function formatCondition(condition: string): string {
  return condition
    .split('_')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ')
}

function formatCurrency(value: number | null): string {
  if (value === null) return '—'
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value)
}

function formatDate(date: string | null): string {
  if (!date) return '—'
  return new Intl.DateTimeFormat('en-US', { dateStyle: 'medium' }).format(new Date(date))
}

async function handleDelete() {
  if (!itemsStore.currentItem) return
  if (!window.confirm(`Delete "${itemsStore.currentItem.name}"? This cannot be undone.`)) return
  await itemsStore.deleteItem(itemsStore.currentItem.id)
  router.push(`/collections/${collectionId}`)
}

function onItemSaved() {
  showEditModal.value = false
  itemsStore.fetchItem(itemId)
}
</script>

<template>
  <div class="item-detail">
    <div class="page-header">
      <RouterLink :to="`/collections/${collectionId}`" class="back-link">← Back to Collection</RouterLink>
    </div>

    <ItemModal
      v-if="itemsStore.currentItem"
      :show="showEditModal"
      :collection-id="Number(collectionId)"
      :item="itemsStore.currentItem"
      @close="showEditModal = false"
      @saved="onItemSaved"
    />

    <div v-if="itemsStore.loading" class="loading">Loading...</div>

    <div v-else-if="itemsStore.error" class="error">{{ itemsStore.error }}</div>

    <template v-else-if="itemsStore.currentItem">
      <div class="item-header">
        <h1 class="item-name">{{ itemsStore.currentItem.name }}</h1>
        <div class="item-actions">
          <button class="btn-secondary" @click="showEditModal = true">Edit</button>
          <button class="btn-danger" @click="handleDelete">Delete</button>
        </div>
      </div>

      <div class="photo-gallery">
        <template v-if="itemsStore.currentItem.photos && itemsStore.currentItem.photos.length > 0">
          <img
            v-for="photo in itemsStore.currentItem.photos"
            :key="photo.id"
            :src="photo.url"
            :alt="photo.filename"
            class="photo-img"
          />
        </template>
        <div v-else class="photo-placeholder">No photos available</div>
      </div>

      <div class="metadata">
        <div class="metadata-row">
          <span class="metadata-label">Condition</span>
          <span class="metadata-value">{{ formatCondition(itemsStore.currentItem.condition) }}</span>
        </div>
        <div class="metadata-row">
          <span class="metadata-label">Estimated Value</span>
          <span class="metadata-value">{{ formatCurrency(itemsStore.currentItem.estimated_value) }}</span>
        </div>
        <div class="metadata-row">
          <span class="metadata-label">Acquisition Date</span>
          <span class="metadata-value">{{ formatDate(itemsStore.currentItem.acquisition_date) }}</span>
        </div>
        <div class="metadata-row">
          <span class="metadata-label">Notes</span>
          <span class="metadata-value">{{ itemsStore.currentItem.notes || '—' }}</span>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.item-detail {
  max-width: 800px;
}

.page-header {
  margin-bottom: 1rem;
}

.back-link {
  color: #1e66f5;
  text-decoration: none;
  font-size: 0.9rem;
}

.back-link:hover {
  text-decoration: underline;
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

.item-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.item-actions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
}

.item-name {
  font-size: 1.75rem;
  font-weight: 700;
  color: #1e1e2e;
  margin-bottom: 0;
}

.btn-secondary {
  background: #eee;
  color: #333;
  border: none;
  border-radius: 6px;
  padding: 0.5rem 1.25rem;
  font-size: 0.9rem;
  cursor: pointer;
}

.btn-danger {
  background: #d20f39;
  color: #fff;
  border: none;
  border-radius: 6px;
  padding: 0.5rem 1.25rem;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
}

.photo-gallery {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
  margin-bottom: 2rem;
}

.photo-img {
  width: 200px;
  height: 200px;
  object-fit: cover;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.photo-placeholder {
  width: 200px;
  height: 200px;
  background: #f5f5f5;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #aaa;
  font-size: 0.9rem;
}

.metadata {
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
  overflow: hidden;
}

.metadata-row {
  display: flex;
  padding: 0.85rem 1.25rem;
  border-bottom: 1px solid #f0f0f0;
}

.metadata-row:last-child {
  border-bottom: none;
}

.metadata-label {
  font-size: 0.85rem;
  color: #666;
  width: 160px;
  flex-shrink: 0;
}

.metadata-value {
  font-size: 0.9rem;
  color: #1e1e2e;
}
</style>
