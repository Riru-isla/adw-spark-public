<script setup lang="ts">
import { ref, computed } from 'vue'
import { useTransactionsStore } from '@/stores/transactions'
import type { Category } from '@/api/index'

const props = defineProps<{
  categories: Category[]
  onSuccess?: () => void
}>()

const emit = defineEmits<{
  saved: []
}>()

const store = useTransactionsStore()

const today = new Date().toISOString().slice(0, 10)

const amount = ref('')
const date = ref(today)
const transaction_type = ref<'income' | 'expense' | ''>('')
const expense_kind = ref<'fixed' | 'variable' | ''>('')
const category_id = ref<number | ''>('')
const notes = ref('')

const errors = ref<Record<string, string>>({})

const showExpenseKind = computed(() => transaction_type.value === 'expense')

function validate(): boolean {
  const e: Record<string, string> = {}
  if (!amount.value || isNaN(Number(amount.value)) || Number(amount.value) <= 0) {
    e.amount = 'Amount is required'
  }
  if (!date.value) {
    e.date = 'Date is required'
  }
  if (!transaction_type.value) {
    e.transaction_type = 'Type is required'
  }
  if (transaction_type.value === 'expense' && !expense_kind.value) {
    e.expense_kind = 'Expense kind is required for expenses'
  }
  if (!category_id.value) {
    e.category_id = 'Category is required'
  }
  errors.value = e
  return Object.keys(e).length === 0
}

async function handleSubmit() {
  if (!validate()) return

  await store.addTransaction({
    amount: Number(amount.value),
    date: date.value,
    transaction_type: transaction_type.value as 'income' | 'expense',
    expense_kind: transaction_type.value === 'expense' ? (expense_kind.value as 'fixed' | 'variable') : null,
    category_id: Number(category_id.value),
    notes: notes.value.trim() || null,
  })

  // reset
  amount.value = ''
  date.value = today
  transaction_type.value = ''
  expense_kind.value = ''
  category_id.value = ''
  notes.value = ''
  errors.value = {}

  emit('saved')
  props.onSuccess?.()
}
</script>

<template>
  <form class="transaction-form" @submit.prevent="handleSubmit">
    <div class="form-row">
      <div class="field">
        <label for="tx-amount">Amount</label>
        <input id="tx-amount" v-model="amount" type="number" step="0.01" min="0" placeholder="0.00" />
        <span v-if="errors.amount" class="field-error">{{ errors.amount }}</span>
      </div>

      <div class="field">
        <label for="tx-date">Date</label>
        <input id="tx-date" v-model="date" type="date" />
        <span v-if="errors.date" class="field-error">{{ errors.date }}</span>
      </div>
    </div>

    <div class="form-row">
      <div class="field">
        <label for="tx-type">Type</label>
        <select id="tx-type" v-model="transaction_type">
          <option value="">Select type</option>
          <option value="income">Income</option>
          <option value="expense">Expense</option>
        </select>
        <span v-if="errors.transaction_type" class="field-error">{{ errors.transaction_type }}</span>
      </div>

      <div v-if="showExpenseKind" class="field">
        <label for="tx-kind">Expense Kind</label>
        <select id="tx-kind" v-model="expense_kind">
          <option value="">Select kind</option>
          <option value="fixed">Fixed</option>
          <option value="variable">Variable</option>
        </select>
        <span v-if="errors.expense_kind" class="field-error">{{ errors.expense_kind }}</span>
      </div>
    </div>

    <div class="field">
      <label for="tx-category">Category</label>
      <select id="tx-category" v-model="category_id">
        <option value="">Select category</option>
        <option v-for="cat in categories" :key="cat.id" :value="cat.id">
          {{ cat.name }}
        </option>
      </select>
      <span v-if="errors.category_id" class="field-error">{{ errors.category_id }}</span>
    </div>

    <div class="field">
      <label for="tx-notes">Notes <span class="optional">(optional)</span></label>
      <textarea id="tx-notes" v-model="notes" rows="2" placeholder="Optional note..." />
    </div>

    <div class="form-actions">
      <button type="submit" class="btn-primary">Add Transaction</button>
    </div>
  </form>
</template>

<style scoped>
.transaction-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.form-row {
  display: flex;
  gap: 1rem;
}

.form-row .field {
  flex: 1;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

.field label {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-heading);
}

.optional {
  font-weight: 400;
  color: var(--color-text);
  opacity: 0.6;
  font-size: 0.8rem;
}

.field input,
.field select,
.field textarea {
  padding: 0.5rem 0.75rem;
  border: 1px solid var(--color-border);
  border-radius: 6px;
  background: var(--color-background);
  color: var(--color-text);
  font-size: 0.95rem;
  font-family: inherit;
}

.field textarea {
  resize: vertical;
}

.field-error {
  font-size: 0.8rem;
  color: #e53e3e;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
}

.btn-primary {
  padding: 0.5rem 1.25rem;
  background: var(--vt-c-indigo);
  color: #fff;
  border: none;
  border-radius: 6px;
  font-size: 0.95rem;
  cursor: pointer;
}
</style>
