<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useDashboardStore } from '@/stores/dashboard'
import { useBudgetsStore } from '@/stores/budgets'
import SpendingPieChart from '@/components/SpendingPieChart.vue'
import MonthlyTrendChart from '@/components/MonthlyTrendChart.vue'
import PetMascot from '@/components/PetMascot.vue'
import type { Budget } from '@/api/index'

const dashboardStore = useDashboardStore()
const budgetsStore = useBudgetsStore()

const now = new Date()

onMounted(() => {
  dashboardStore.fetchData()
  budgetsStore.fetchBudgets(now.getMonth() + 1, now.getFullYear())
})

function rawPercent(budget: Budget): number {
  if (!budget.limit_amount) return 0
  return (budget.spent_amount / budget.limit_amount) * 100
}

function barClass(budget: Budget): string {
  const pct = rawPercent(budget)
  if (pct > 90) return 'bar-red'
  if (pct >= 70) return 'bar-yellow'
  return 'bar-green'
}

function barStyle(budget: Budget): Record<string, string> {
  const width = `${Math.min(rawPercent(budget), 100)}%`
  if (barClass(budget) === 'bar-green') {
    return { width, background: budget.category.color || '#48bb78' }
  }
  return { width }
}

function formatAmount(amount: number): string {
  return `$${amount.toFixed(2)}`
}

const categoryBreakdown = computed(() => dashboardStore.data?.category_breakdown ?? [])
const monthlyTrend = computed(() => dashboardStore.data?.monthly_trend ?? [])
const budgets = computed(() => budgetsStore.budgets)
const loading = computed(() => dashboardStore.loading)
const petMood = computed(() => dashboardStore.data?.pet_mood ?? 'happy')
</script>

<template>
  <div class="dashboard-page">
    <h1 class="dashboard-title">📊 Dashboard</h1>

    <div v-if="loading" class="state-msg">Loading…</div>

    <template v-else>
      <div class="mascot-row">
        <PetMascot v-if="dashboardStore.data" :mood="petMood" />
      </div>

      <div class="dashboard-grid">
        <!-- Spending This Month -->
        <div class="dashboard-card">
          <h2 class="section-heading">🍩 Spending This Month</h2>
          <div v-if="categoryBreakdown.length === 0" class="empty-state">No spending recorded this month.</div>
          <SpendingPieChart v-else :category-breakdown="categoryBreakdown" />
        </div>

        <!-- Budget Status -->
        <div class="dashboard-card">
          <h2 class="section-heading">🎯 Budget Status</h2>
          <div v-if="budgets.length === 0" class="empty-state">No budgets set for this month.</div>
          <div v-else class="budget-list">
            <div v-for="budget in budgets" :key="budget.id" class="budget-row">
              <div class="budget-row-header">
                <span class="color-dot" :style="{ background: budget.category.color }" />
                <span class="cat-icon">{{ budget.category.icon }}</span>
                <span class="cat-name">{{ budget.category.name }}</span>
                <span class="budget-amounts">
                  {{ formatAmount(budget.spent_amount) }} / {{ formatAmount(budget.limit_amount) }}
                </span>
              </div>
              <div class="progress-bar-track">
                <div
                  class="progress-bar-fill"
                  :class="barClass(budget)"
                  :style="barStyle(budget)"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 6-Month Trend -->
      <div class="dashboard-card full-width">
        <h2 class="section-heading">📈 6-Month Trend</h2>
        <MonthlyTrendChart :monthly-trend="monthlyTrend" />
      </div>
    </template>
  </div>
</template>

<style scoped>
.dashboard-page {
  max-width: 900px;
}

.dashboard-title {
  font-size: 1.5rem;
  font-weight: 600;
  color: var(--color-heading);
  margin-bottom: 1.5rem;
}

.state-msg {
  color: var(--color-text);
  padding: 1rem 0;
}

.mascot-row {
  display: flex;
  justify-content: flex-start;
  margin-bottom: 1rem;
}

.dashboard-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.25rem;
  margin-bottom: 1.25rem;
}

@media (max-width: 640px) {
  .dashboard-grid {
    grid-template-columns: 1fr;
  }
}

.dashboard-card {
  padding: 1.25rem;
  background: var(--color-background-soft);
  border: 1px solid var(--color-border);
  border-radius: 10px;
}

.full-width {
  width: 100%;
}

.section-heading {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-heading);
  margin-bottom: 1rem;
}

.empty-state {
  color: var(--color-text);
  opacity: 0.6;
  font-size: 0.9rem;
}

.budget-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.budget-row-header {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  margin-bottom: 0.4rem;
}

.color-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  flex-shrink: 0;
}

.cat-icon {
  font-size: 1rem;
}

.cat-name {
  flex: 1;
  font-weight: 500;
  font-size: 0.9rem;
  color: var(--color-heading);
}

.budget-amounts {
  font-size: 0.82rem;
  color: var(--color-text);
}

.progress-bar-track {
  height: 8px;
  background: var(--color-background-mute);
  border-radius: 4px;
  overflow: hidden;
}

.progress-bar-fill {
  height: 100%;
  border-radius: 4px;
  transition: width 0.3s ease;
}

.bar-yellow {
  background: #d69e2e;
}

.bar-red {
  background: #e53e3e;
}
</style>
