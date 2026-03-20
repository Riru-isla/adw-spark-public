<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useBudgetsStore } from '@/stores/budgets'
import { useCategoriesStore } from '@/stores/categories'
import type { Budget } from '@/api/index'

const budgetsStore = useBudgetsStore()
const categoriesStore = useCategoriesStore()

const showForm = ref(false)
const formCategoryId = ref<number | ''>('')
const formLimitAmount = ref<number | ''>('')

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
]

const monthLabel = computed(() => `${MONTHS[budgetsStore.month - 1]} ${budgetsStore.year}`)

function prevMonth() {
  let m = budgetsStore.month - 1
  let y = budgetsStore.year
  if (m < 1) { m = 12; y -= 1 }
  budgetsStore.setMonth(m, y)
}

function nextMonth() {
  let m = budgetsStore.month + 1
  let y = budgetsStore.year
  if (m > 12) { m = 1; y += 1 }
  budgetsStore.setMonth(m, y)
}

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

function openForm() {
  formCategoryId.value = ''
  formLimitAmount.value = ''
  showForm.value = true
}

function closeForm() {
  showForm.value = false
}

async function handleSubmit() {
  if (!formCategoryId.value || !formLimitAmount.value) return
  await budgetsStore.saveBudget({
    category_id: Number(formCategoryId.value),
    month: budgetsStore.month,
    year: budgetsStore.year,
    limit_amount: Number(formLimitAmount.value),
  })
  closeForm()
}

onMounted(() => {
  budgetsStore.fetchBudgets(budgetsStore.month, budgetsStore.year)
  if (categoriesStore.categories.length === 0) {
    categoriesStore.fetchCategories()
  }
})
</script>

<template>
  <div class="budgets-page">
    <div class="page-header">
      <h1>Budgets</h1>
      <button class="btn-primary" @click="openForm">Set Budget</button>
    </div>

    <div class="month-nav">
      <button data-testid="prev-month" class="btn-icon" @click="prevMonth">&#8249;</button>
      <span class="month-label">{{ monthLabel }}</span>
      <button data-testid="next-month" class="btn-icon" @click="nextMonth">&#8250;</button>
    </div>

    <div v-if="budgetsStore.loading" class="state-msg">Loading…</div>
    <div v-else-if="budgetsStore.error" class="state-msg error">{{ budgetsStore.error }}</div>
    <div v-else-if="budgetsStore.budgets.length === 0" class="state-msg">
      No budgets set for {{ monthLabel }}. Click "Set Budget" to get started.
    </div>

    <div v-else class="budget-list">
      <div v-for="budget in budgetsStore.budgets" :key="budget.id" class="budget-card">
        <div class="budget-card-header">
          <span class="cat-icon">{{ budget.category.icon }}</span>
          <span class="cat-name">{{ budget.category.name }}</span>
          <span class="budget-amounts">
            <span class="spent">{{ formatAmount(budget.spent_amount) }}</span>
            <span class="separator"> / </span>
            <span class="limit">{{ formatAmount(budget.limit_amount) }}</span>
          </span>
        </div>
        <div class="progress-bar-track">
          <div
            class="progress-bar-fill"
            :class="barClass(budget)"
            :style="barStyle(budget)"
          />
        </div>
        <div class="budget-card-footer">
          <span v-if="budget.spent_amount > budget.limit_amount" class="over-budget">Over budget</span>
          <span v-else class="remaining">{{ formatAmount(budget.remaining_amount) }} remaining</span>
        </div>
      </div>
    </div>

    <div v-if="budgetsStore.budgets.length > 0" class="totals-footer">
      <span>Total budgeted: {{ formatAmount(budgetsStore.totalLimit) }}</span>
      <span>Total spent: {{ formatAmount(budgetsStore.totalSpent) }}</span>
    </div>

    <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
      <div class="modal">
        <h2>Set Budget</h2>
        <form @submit.prevent="handleSubmit">
          <div class="form-group">
            <label for="category_id">Category</label>
            <select id="category_id" name="category_id" v-model="formCategoryId" required>
              <option value="" disabled>Select a category</option>
              <option v-for="cat in categoriesStore.categories" :key="cat.id" :value="cat.id">
                {{ cat.icon }} {{ cat.name }}
              </option>
            </select>
          </div>
          <div class="form-group">
            <label for="limit_amount">Monthly Limit</label>
            <input
              id="limit_amount"
              name="limit_amount"
              type="number"
              v-model.number="formLimitAmount"
              min="0.01"
              step="0.01"
              required
            />
          </div>
          <div class="form-group">
            <label>Month</label>
            <span class="form-static">{{ monthLabel }}</span>
          </div>
          <div class="form-actions">
            <button type="button" @click="closeForm">Cancel</button>
            <button type="submit" class="btn-primary">Save</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.budgets-page {
  max-width: 800px;
}

.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}

.page-header h1 {
  font-size: 1.5rem;
  font-weight: 600;
  color: var(--color-heading);
}

.month-nav {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1.5rem;
}

.month-label {
  font-size: 1.05rem;
  font-weight: 500;
  color: var(--color-heading);
  min-width: 140px;
  text-align: center;
}

.btn-icon {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 1.4rem;
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  color: var(--color-text);
}

.btn-icon:hover {
  background: var(--color-background-mute);
}

.state-msg {
  color: var(--color-text);
  padding: 1rem 0;
}

.state-msg.error {
  color: #e53e3e;
}

.budget-list {
  display: flex;
  flex-direction: column;
  gap: 0.8rem;
}

.budget-card {
  padding: 0.85rem 1rem;
  background: var(--color-background-soft);
  border: 1px solid var(--color-border);
  border-radius: 8px;
}

.budget-card-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.6rem;
}

.cat-icon {
  font-size: 1.1rem;
}

.cat-name {
  flex: 1;
  font-weight: 500;
  color: var(--color-heading);
}

.budget-amounts {
  font-size: 0.9rem;
  color: var(--color-text);
}

.progress-bar-track {
  height: 10px;
  background: var(--color-background-mute);
  border-radius: 5px;
  overflow: hidden;
  margin-bottom: 0.4rem;
}

.progress-bar-fill {
  height: 100%;
  border-radius: 5px;
  transition: width 0.3s ease;
}

.bar-yellow {
  background: #d69e2e;
}

.bar-red {
  background: #e53e3e;
}

.budget-card-footer {
  font-size: 0.82rem;
}

.remaining {
  color: var(--color-text);
  opacity: 0.75;
}

.over-budget {
  color: #e53e3e;
  font-weight: 600;
}

.totals-footer {
  display: flex;
  gap: 2rem;
  margin-top: 1.25rem;
  padding-top: 1rem;
  border-top: 1px solid var(--color-border);
  font-size: 0.95rem;
  color: var(--color-text);
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

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  margin-bottom: 1rem;
}

.form-group label {
  font-size: 0.9rem;
  color: var(--color-text);
}

.form-group select,
.form-group input {
  padding: 0.45rem 0.6rem;
  border: 1px solid var(--color-border);
  border-radius: 5px;
  background: var(--color-background-soft);
  color: var(--color-text);
  font-size: 0.95rem;
}

.form-static {
  font-size: 0.95rem;
  color: var(--color-text);
  padding: 0.45rem 0;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.6rem;
  margin-top: 0.5rem;
}

.form-actions button[type='button'] {
  padding: 0.45rem 1rem;
  background: none;
  border: 1px solid var(--color-border);
  border-radius: 5px;
  cursor: pointer;
  color: var(--color-text);
}

@media (max-width: 640px) {
  .budgets-page {
    max-width: 100%;
  }
}
</style>
