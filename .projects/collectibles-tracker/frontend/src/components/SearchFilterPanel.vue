<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useCollectionsStore } from '@/stores/collections'
import type { SearchParams } from '@/services/api'

const emit = defineEmits<{
  search: [params: SearchParams]
}>()

const collectionsStore = useCollectionsStore()

const query = ref('')
const collectionId = ref('')
const category = ref('')
const condition = ref('')
const valueMin = ref('')
const valueMax = ref('')

let debounceTimer: ReturnType<typeof setTimeout> | null = null

const CONDITIONS = ['mint', 'near_mint', 'good', 'fair', 'poor']

function formatConditionLabel(c: string) {
  return c.split('_').map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(' ')
}

function currentParams(): SearchParams {
  const p: SearchParams = {}
  if (query.value) p.query = query.value
  if (collectionId.value) p.collection_id = collectionId.value
  if (category.value) p.category = category.value
  if (condition.value) p.condition = condition.value
  if (valueMin.value) p.value_min = valueMin.value
  if (valueMax.value) p.value_max = valueMax.value
  return p
}

function emitSearch() {
  emit('search', currentParams())
}

function debouncedEmit() {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(emitSearch, 300)
}

watch(query, debouncedEmit)
watch([collectionId, category, condition, valueMin, valueMax], debouncedEmit)

function clearFilters() {
  query.value = ''
  collectionId.value = ''
  category.value = ''
  condition.value = ''
  valueMin.value = ''
  valueMax.value = ''
  emit('search', {})
}

const activeFilterCount = computed(() => {
  return [query.value, collectionId.value, category.value, condition.value, valueMin.value, valueMax.value]
    .filter(Boolean).length
})
</script>

<template>
  <div class="search-filter-panel">
    <div class="filter-row">
      <div class="filter-group filter-group--wide">
        <label class="filter-label">Search</label>
        <input
          v-model="query"
          type="text"
          class="filter-input"
          placeholder="Search by name or notes..."
          data-testid="search-query"
        />
      </div>

      <div class="filter-group">
        <label class="filter-label">Collection</label>
        <select v-model="collectionId" class="filter-select" data-testid="search-collection">
          <option value="">All Collections</option>
          <option v-for="c in collectionsStore.collections" :key="c.id" :value="c.id">
            {{ c.name }}
          </option>
        </select>
      </div>

      <div class="filter-group">
        <label class="filter-label">Category</label>
        <input
          v-model="category"
          type="text"
          class="filter-input"
          placeholder="Category..."
          data-testid="search-category"
        />
      </div>

      <div class="filter-group">
        <label class="filter-label">Condition</label>
        <select v-model="condition" class="filter-select" data-testid="search-condition">
          <option value="">Any Condition</option>
          <option v-for="c in CONDITIONS" :key="c" :value="c">
            {{ formatConditionLabel(c) }}
          </option>
        </select>
      </div>

      <div class="filter-group filter-group--value">
        <label class="filter-label">Value Range</label>
        <div class="value-range">
          <input
            v-model="valueMin"
            type="number"
            class="filter-input filter-input--value"
            placeholder="Min"
            min="0"
            data-testid="search-value-min"
          />
          <span class="value-sep">–</span>
          <input
            v-model="valueMax"
            type="number"
            class="filter-input filter-input--value"
            placeholder="Max"
            min="0"
            data-testid="search-value-max"
          />
        </div>
      </div>
    </div>

    <div class="filter-actions">
      <button v-if="activeFilterCount > 0" class="btn-clear" @click="clearFilters">
        Clear filters
        <span class="filter-badge">{{ activeFilterCount }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.search-filter-panel {
  background: #fff;
  border-radius: 10px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.08);
  padding: 1.25rem 1.5rem;
  margin-bottom: 1.5rem;
}

.filter-row {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  align-items: flex-end;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  min-width: 140px;
}

.filter-group--wide {
  min-width: 220px;
  flex: 1;
}

.filter-group--value {
  min-width: 180px;
}

.filter-label {
  font-size: 0.75rem;
  font-weight: 600;
  color: #888;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.filter-input,
.filter-select {
  height: 36px;
  padding: 0 0.75rem;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 0.875rem;
  color: #1e1e2e;
  background: #fafafa;
  outline: none;
  transition: border-color 0.15s;
  width: 100%;
}

.filter-input:focus,
.filter-select:focus {
  border-color: #1e66f5;
  background: #fff;
}

.value-range {
  display: flex;
  align-items: center;
  gap: 0.4rem;
}

.filter-input--value {
  width: 70px;
  padding: 0 0.5rem;
}

.value-sep {
  color: #aaa;
  font-size: 0.9rem;
}

.filter-actions {
  margin-top: 0.75rem;
  display: flex;
  justify-content: flex-end;
}

.btn-clear {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  background: none;
  border: 1px solid #ddd;
  border-radius: 6px;
  padding: 0.3rem 0.75rem;
  font-size: 0.8rem;
  color: #666;
  cursor: pointer;
  transition: border-color 0.15s, color 0.15s;
}

.btn-clear:hover {
  border-color: #d20f39;
  color: #d20f39;
}

.filter-badge {
  background: #1e66f5;
  color: #fff;
  border-radius: 999px;
  padding: 0 0.4rem;
  font-size: 0.7rem;
  font-weight: 700;
  line-height: 1.4;
}
</style>
