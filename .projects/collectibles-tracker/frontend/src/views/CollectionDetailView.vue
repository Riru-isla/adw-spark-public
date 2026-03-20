<script setup lang="ts">
import { onMounted, computed, ref, watch } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import { useItemsStore } from '@/stores/items'
import type { Item } from '@/stores/items'
import { useCollectionsStore } from '@/stores/collections'
import ItemModal from '@/components/ItemModal.vue'
import ValueBreakdown from '@/components/ValueBreakdown.vue'

const route = useRoute()
const collectionId = route.params.id as string

const itemsStore = useItemsStore()
const collectionsStore = useCollectionsStore()

const collectionName = computed(() => {
  if (collectionsStore.currentCollection && String(collectionsStore.currentCollection.id) === collectionId) {
    return collectionsStore.currentCollection.name
  }
  const found = collectionsStore.collections.find((c) => String(c.id) === collectionId)
  return found ? found.name : `Collection ${collectionId}`
})

const showItemModal = ref(false)
const editingItem = ref<Item | null>(null)

const viewMode = ref<'grid' | 'list'>(
  (sessionStorage.getItem('itemViewMode') as 'grid' | 'list') || 'grid',
)

watch(viewMode, (val) => {
  sessionStorage.setItem('itemViewMode', val)
})

onMounted(() => {
  itemsStore.fetchItems(collectionId)
  collectionsStore.fetchCollection(collectionId)
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
  return new Date(date).toLocaleDateString()
}

function openAddItem() {
  editingItem.value = null
  showItemModal.value = true
}

function onItemSaved() {
  showItemModal.value = false
  itemsStore.fetchItems(collectionId)
}
</script>

<template>
  <div class="collection-detail">
    <div class="page-header">
      <RouterLink to="/collections" class="back-link">← Back to Collections</RouterLink>
      <div class="page-header-row">
        <h1 class="page-title">{{ collectionName }}</h1>
        <div class="view-toggle">
          <button
            class="view-btn"
            :class="{ active: viewMode === 'grid' }"
            @click="viewMode = 'grid'"
          >
            Grid
          </button>
          <button
            class="view-btn"
            :class="{ active: viewMode === 'list' }"
            @click="viewMode = 'list'"
          >
            List
          </button>
        </div>
        <button class="btn-primary" @click="openAddItem">Add Item</button>
      </div>
    </div>

    <ItemModal
      :show="showItemModal"
      :collection-id="Number(collectionId)"
      :item="editingItem"
      @close="showItemModal = false"
      @saved="onItemSaved"
    />

    <section
      v-if="collectionsStore.currentCollection?.value_by_condition"
      class="value-by-condition"
    >
      <h2 class="section-heading">Value by Condition</h2>
      <ValueBreakdown :breakdown="collectionsStore.currentCollection.value_by_condition" />
    </section>

    <div v-if="itemsStore.loading" class="loading">Loading...</div>

    <div v-else-if="itemsStore.error" class="error">{{ itemsStore.error }}</div>

    <template v-else>
      <div v-if="itemsStore.items.length === 0" class="empty">No items in this collection yet.</div>

      <div v-if="viewMode === 'grid'" class="item-cards">
        <RouterLink
          v-for="item in itemsStore.items"
          :key="item.id"
          :to="`/collections/${collectionId}/items/${item.id}`"
          class="item-card"
        >
          <div class="item-thumbnail">
            <img
              v-if="item.photos && item.photos.length > 0"
              :src="item.photos[0].url"
              :alt="item.name"
              class="thumbnail-img"
            />
            <div v-else class="thumbnail-placeholder">No Photo</div>
          </div>
          <div class="item-info">
            <div class="item-name">{{ item.name }}</div>
            <div class="item-condition">{{ formatCondition(item.condition) }}</div>
            <div class="item-value">{{ formatCurrency(item.estimated_value) }}</div>
          </div>
        </RouterLink>
      </div>

      <table v-else class="item-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Condition</th>
            <th>Value</th>
            <th>Acquired</th>
          </tr>
        </thead>
        <tbody>
          <RouterLink
            v-for="item in itemsStore.items"
            :key="item.id"
            :to="`/collections/${collectionId}/items/${item.id}`"
            custom
            v-slot="{ navigate }"
          >
            <tr class="item-row" @click="navigate">
              <td>{{ item.name }}</td>
              <td>{{ formatCondition(item.condition) }}</td>
              <td>{{ formatCurrency(item.estimated_value) }}</td>
              <td>{{ formatDate(item.acquisition_date) }}</td>
            </tr>
          </RouterLink>
        </tbody>
      </table>
    </template>
  </div>
</template>

<style scoped>
.collection-detail {
  max-width: 1000px;
}

.page-header {
  margin-bottom: 1.5rem;
}

.back-link {
  color: #1e66f5;
  text-decoration: none;
  font-size: 0.9rem;
  display: inline-block;
  margin-bottom: 0.5rem;
}

.back-link:hover {
  text-decoration: underline;
}

.page-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.page-title {
  font-size: 1.75rem;
  font-weight: 700;
  color: #1e1e2e;
}

.view-toggle {
  display: flex;
  border: 1px solid #d0d0d0;
  border-radius: 6px;
  overflow: hidden;
}

.view-btn {
  background: #fff;
  color: #555;
  border: none;
  padding: 0.4rem 0.9rem;
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.15s, color 0.15s;
}

.view-btn + .view-btn {
  border-left: 1px solid #d0d0d0;
}

.view-btn.active {
  background: #1e66f5;
  color: #fff;
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

.value-by-condition {
  background: #fff;
  border-radius: 8px;
  padding: 1rem 1.25rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
  margin-bottom: 1.5rem;
  max-width: 360px;
}

.section-heading {
  font-size: 1rem;
  font-weight: 600;
  color: #1e1e2e;
  margin-bottom: 0.75rem;
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

.item-cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 1rem;
}

.item-card {
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
  overflow: hidden;
  text-decoration: none;
  color: inherit;
  display: flex;
  flex-direction: column;
  transition: box-shadow 0.15s;
}

.item-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
}

.item-thumbnail {
  width: 100%;
  height: 140px;
  background: #f5f5f5;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.thumbnail-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.thumbnail-placeholder {
  color: #aaa;
  font-size: 0.85rem;
}

.item-info {
  padding: 0.75rem 1rem;
}

.item-name {
  font-weight: 700;
  font-size: 0.95rem;
  color: #1e1e2e;
  margin-bottom: 0.25rem;
}

.item-condition {
  font-size: 0.8rem;
  color: #666;
  margin-bottom: 0.25rem;
}

.item-value {
  font-size: 0.85rem;
  font-weight: 600;
  color: #1e1e2e;
}

.item-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.9rem;
}

.item-table th {
  background: #f5f5f5;
  color: #888;
  font-weight: 600;
  text-align: left;
  padding: 0.6rem 1rem;
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.item-row {
  cursor: pointer;
  border-bottom: 1px solid #f0f0f0;
}

.item-row td {
  padding: 0.7rem 1rem;
  color: #1e1e2e;
}

.item-row:hover td {
  background: #f9f9f9;
}
</style>
