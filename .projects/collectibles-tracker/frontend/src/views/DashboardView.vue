<script setup lang="ts">
import { onMounted } from 'vue'
import { useDashboardStore } from '@/stores/dashboard'
import ValueBreakdown from '@/components/ValueBreakdown.vue'

const dashboardStore = useDashboardStore()

onMounted(() => {
  dashboardStore.fetchDashboard()
})

function formatCurrency(value: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value)
}
</script>

<template>
  <div class="dashboard">
    <h1 class="page-title">Dashboard</h1>

    <div v-if="dashboardStore.loading" class="loading">Loading...</div>

    <div v-else-if="dashboardStore.error" class="error">
      {{ dashboardStore.error }}
    </div>

    <template v-else>
      <div class="stat-cards">
        <div class="stat-card">
          <div class="stat-value">{{ dashboardStore.totalCollections }}</div>
          <div class="stat-label">Total Collections</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ dashboardStore.totalItems }}</div>
          <div class="stat-label">Total Items</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ formatCurrency(dashboardStore.totalEstimatedValue) }}</div>
          <div class="stat-label">Total Estimated Value</div>
        </div>
      </div>

      <section class="value-by-condition">
        <h2>Value by Condition</h2>
        <ValueBreakdown :breakdown="dashboardStore.valueByCondition" />
      </section>

      <section class="recently-added">
        <h2>Recently Added</h2>
        <div v-if="dashboardStore.recentlyAddedItems.length === 0" class="empty">
          No items yet.
        </div>
        <div class="item-cards">
          <div
            v-for="item in dashboardStore.recentlyAddedItems"
            :key="item.id"
            class="item-card"
          >
            <img
              v-if="item.photos && item.photos.length > 0"
              :src="item.photos[0].url"
              :alt="item.name"
              class="item-thumbnail"
            />
            <div v-else class="item-thumbnail-placeholder">No photo</div>
            <div class="item-info">
              <div class="item-name">{{ item.name }}</div>
              <div class="item-collection">{{ item.collection_name }}</div>
            </div>
          </div>
        </div>
      </section>
    </template>
  </div>
</template>

<style scoped>
.dashboard {
  max-width: 1000px;
}

.page-title {
  font-size: 1.75rem;
  font-weight: 700;
  margin-bottom: 1.5rem;
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

.stat-cards {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
  margin-bottom: 2rem;
}

.stat-card {
  background: #fff;
  border-radius: 8px;
  padding: 1.25rem 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.stat-value {
  font-size: 2rem;
  font-weight: 700;
  color: #1e1e2e;
}

.stat-label {
  font-size: 0.85rem;
  color: #888;
  margin-top: 0.25rem;
}

.value-by-condition {
  background: #fff;
  border-radius: 8px;
  padding: 1rem 1.25rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
  margin-bottom: 2rem;
  max-width: 360px;
}

.value-by-condition h2 {
  font-size: 1.25rem;
  font-weight: 600;
  margin-bottom: 1rem;
  color: #1e1e2e;
}

.recently-added h2 {
  font-size: 1.25rem;
  font-weight: 600;
  margin-bottom: 1rem;
  color: #1e1e2e;
}

.item-cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 1rem;
}

.item-card {
  background: #fff;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.item-thumbnail {
  width: 100%;
  height: 140px;
  object-fit: cover;
}

.item-thumbnail-placeholder {
  width: 100%;
  height: 140px;
  background: #eee;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #aaa;
  font-size: 0.8rem;
}

.item-info {
  padding: 0.75rem;
}

.item-name {
  font-weight: 600;
  font-size: 0.9rem;
  color: #1e1e2e;
}

.item-collection {
  font-size: 0.8rem;
  color: #888;
  margin-top: 0.2rem;
}
</style>
