<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useCategoriesStore } from '@/stores/categories'
import { useTransactionsStore } from '@/stores/transactions'
import TransactionForm from '@/components/TransactionForm.vue'
import type { TransactionFilters } from '@/api/index'

const categoriesStore = useCategoriesStore()
const txStore = useTransactionsStore()

const filterCategoryId = ref<number | ''>('')
const filterType = ref<'income' | 'expense' | ''>('')
const filterKind = ref<'fixed' | 'variable' | ''>('')
const filterStartDate = ref('')
const filterEndDate = ref('')

onMounted(() => {
  if (categoriesStore.categories.length === 0) categoriesStore.fetchCategories()
  txStore.fetchTransactions()
})

function applyFilters() {
  const f: TransactionFilters = {}
  if (filterCategoryId.value) f.category_id = Number(filterCategoryId.value)
  if (filterType.value) f.transaction_type = filterType.value
  if (filterKind.value) f.expense_kind = filterKind.value
  if (filterStartDate.value) f.start_date = filterStartDate.value
  if (filterEndDate.value) f.end_date = filterEndDate.value
  txStore.setFilters(f)
}

function clearFilters() {
  filterCategoryId.value = ''
  filterType.value = ''
  filterKind.value = ''
  filterStartDate.value = ''
  filterEndDate.value = ''
  txStore.setFilters({})
}

async function handleDelete(id: number) {
  if (window.confirm('Delete this transaction?')) {
    await txStore.removeTransaction(id)
  }
}

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(amount)
}

function truncate(text: string | null, len = 40): string {
  if (!text) return ''
  return text.length > len ? text.slice(0, len) + '…' : text
}
</script>

<template>
  <div class="transactions-page">
    <!-- Add Transaction -->
    <section class="section">
      <h2 class="section-title">Add Transaction</h2>
      <TransactionForm :categories="categoriesStore.categories" />
    </section>

    <!-- Filters -->
    <section class="section">
      <h2 class="section-title">Filters</h2>
      <div class="filter-row">
        <select v-model="filterCategoryId" @change="applyFilters">
          <option value="">All categories</option>
          <option v-for="cat in categoriesStore.categories" :key="cat.id" :value="cat.id">
            {{ cat.name }}
          </option>
        </select>

        <select v-model="filterType" @change="applyFilters">
          <option value="">All types</option>
          <option value="income">Income</option>
          <option value="expense">Expense</option>
        </select>

        <select v-model="filterKind" @change="applyFilters">
          <option value="">All kinds</option>
          <option value="fixed">Fixed</option>
          <option value="variable">Variable</option>
        </select>

        <input v-model="filterStartDate" type="date" placeholder="Start date" @change="applyFilters" />
        <input v-model="filterEndDate" type="date" placeholder="End date" @change="applyFilters" />

        <button class="btn-secondary" @click="clearFilters">Clear filters</button>
      </div>
    </section>

    <!-- Transaction List -->
    <section class="section">
      <h2 class="section-title">Transactions</h2>

      <div v-if="txStore.loading" class="state-msg">Loading…</div>
      <div v-else-if="txStore.error" class="state-msg error">{{ txStore.error }}</div>
      <div v-else-if="txStore.transactions.length === 0" class="state-msg">No transactions found.</div>

      <div v-else class="tx-list">
        <div
          v-for="tx in txStore.transactions"
          :key="tx.id"
          class="tx-row"
        >
          <span class="tx-date">{{ tx.date }}</span>
          <span
            class="tx-category"
            :style="{ borderLeft: `4px solid ${tx.category?.color ?? '#ccc'}` }"
          >
            {{ tx.category?.name ?? '—' }}
          </span>
          <span class="tx-amount" :class="tx.transaction_type">
            {{ formatCurrency(tx.amount) }}
          </span>
          <span class="tx-badge type-badge" :class="tx.transaction_type">
            {{ tx.transaction_type }}
          </span>
          <span v-if="tx.expense_kind" class="tx-badge kind-badge">
            {{ tx.expense_kind }}
          </span>
          <span class="tx-notes">{{ truncate(tx.notes) }}</span>
          <button class="btn-icon btn-danger" title="Delete" @click="handleDelete(tx.id)">&#128465;</button>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.transactions-page {
  max-width: 900px;
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.section {
  background: var(--color-background-soft);
  border: 1px solid var(--color-border);
  border-radius: 10px;
  padding: 1.25rem 1.5rem;
}

.section-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-heading);
  margin-bottom: 1rem;
}

.filter-row {
  display: flex;
  flex-wrap: wrap;
  gap: 0.6rem;
  align-items: center;
}

.filter-row select,
.filter-row input[type='date'] {
  padding: 0.45rem 0.7rem;
  border: 1px solid var(--color-border);
  border-radius: 6px;
  background: var(--color-background);
  color: var(--color-text);
  font-size: 0.9rem;
}

.state-msg {
  color: var(--color-text);
  padding: 0.5rem 0;
}

.state-msg.error {
  color: #e53e3e;
}

.tx-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.tx-row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.65rem 0.75rem;
  background: var(--color-background);
  border: 1px solid var(--color-border);
  border-radius: 7px;
  flex-wrap: wrap;
}

.tx-date {
  font-size: 0.85rem;
  color: var(--color-text);
  min-width: 90px;
}

.tx-category {
  padding-left: 0.5rem;
  font-size: 0.9rem;
  font-weight: 500;
  color: var(--color-heading);
  min-width: 100px;
}

.tx-amount {
  font-weight: 600;
  min-width: 80px;
}

.tx-amount.income {
  color: #38a169;
}

.tx-amount.expense {
  color: #e53e3e;
}

.tx-badge {
  font-size: 0.75rem;
  padding: 0.15rem 0.5rem;
  border-radius: 999px;
  text-transform: capitalize;
}

.type-badge.income {
  background: #c6f6d5;
  color: #276749;
}

.type-badge.expense {
  background: #fed7d7;
  color: #9b2335;
}

.kind-badge {
  background: var(--color-background-mute);
  color: var(--color-text);
}

.tx-notes {
  flex: 1;
  font-size: 0.85rem;
  color: var(--color-text);
  opacity: 0.75;
  min-width: 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.btn-icon {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 1rem;
  padding: 0.2rem 0.4rem;
  border-radius: 4px;
  color: var(--color-text);
  margin-left: auto;
}

.btn-icon:hover {
  background: var(--color-background-mute);
}

.btn-danger {
  color: #e53e3e;
}

.btn-secondary {
  padding: 0.45rem 1rem;
  background: transparent;
  color: var(--color-text);
  border: 1px solid var(--color-border);
  border-radius: 6px;
  font-size: 0.9rem;
  cursor: pointer;
}

@media (max-width: 640px) {
  .filter-row {
    flex-direction: column;
    align-items: stretch;
  }
}
</style>
