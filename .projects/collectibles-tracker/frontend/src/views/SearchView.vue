<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import { useItemsStore } from '@/stores/items'
import { useCollectionsStore } from '@/stores/collections'
import SearchFilterPanel from '@/components/SearchFilterPanel.vue'
import type { SearchParams } from '@/services/api'

const itemsStore = useItemsStore()
const collectionsStore = useCollectionsStore()

const hasSearched = ref(false)

onMounted(() => {
  if (collectionsStore.collections.length === 0) {
    collectionsStore.fetchCollections()
  }
})

async function onSearch(params: SearchParams) {
  hasSearched.value = true
  await itemsStore.searchItems(params)
}

function collectionName(collectionId: number): string {
  const c = collectionsStore.collections.find((c) => c.id === collectionId)
  return c ? c.name : `Collection ${collectionId}`
}

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
</script>

<template>
  <div class="search-view">
    <h1 class="page-title">Search</h1>

    <SearchFilterPanel @search="onSearch" />

    <div v-if="itemsStore.searching" class="loading">Searching...</div>

    <template v-else-if="hasSearched">
      <div class="results-header">
        <span class="results-count">
          {{ itemsStore.searchResults.length }}
          {{ itemsStore.searchResults.length === 1 ? 'result' : 'results' }}
        </span>
      </div>

      <div v-if="itemsStore.searchResults.length === 0" class="empty">
        No items match your search.
      </div>

      <div v-else class="item-cards">
        <RouterLink
          v-for="item in itemsStore.searchResults"
          :key="item.id"
          :to="`/collections/${item.collection_id}/items/${item.id}`"
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
            <div class="item-collection">{{ collectionName(item.collection_id) }}</div>
            <div class="item-condition">{{ formatCondition(item.condition) }}</div>
            <div class="item-value">{{ formatCurrency(item.estimated_value) }}</div>
          </div>
        </RouterLink>
      </div>
    </template>

    <div v-else class="prompt">
      Use the search bar and filters above to find items across all your collections.
    </div>
  </div>
</template>

<style scoped>
.search-view {
  max-width: 1000px;
}

.page-title {
  font-size: 1.75rem;
  font-weight: 700;
  color: #1e1e2e;
  margin-bottom: 1.5rem;
}

.results-header {
  margin-bottom: 1rem;
}

.results-count {
  font-size: 0.85rem;
  color: #888;
  font-weight: 500;
}

.loading {
  color: #666;
  padding: 1rem 0;
}

.empty,
.prompt {
  color: #888;
  padding: 2rem 0;
  text-align: center;
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
  margin-bottom: 0.2rem;
}

.item-collection {
  font-size: 0.75rem;
  color: #1e66f5;
  margin-bottom: 0.2rem;
  font-weight: 500;
}

.item-condition {
  font-size: 0.8rem;
  color: #666;
  margin-bottom: 0.2rem;
}

.item-value {
  font-size: 0.85rem;
  font-weight: 600;
  color: #1e1e2e;
}
</style>
