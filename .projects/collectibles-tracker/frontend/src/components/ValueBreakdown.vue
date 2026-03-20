<script setup lang="ts">
const CONDITION_ORDER = ['mint', 'near_mint', 'good', 'fair', 'poor'] as const
const CONDITION_LABELS: Record<string, string> = {
  mint: 'Mint',
  near_mint: 'Near Mint',
  good: 'Good',
  fair: 'Fair',
  poor: 'Poor',
}

const props = defineProps<{
  breakdown: Record<string, number>
}>()

function formatCurrency(value: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value)
}

const rows = CONDITION_ORDER
  .map((key) => ({ key, label: CONDITION_LABELS[key], value: props.breakdown[key] ?? 0 }))
  .filter((row) => row.value > 0)
</script>

<template>
  <div class="value-breakdown">
    <div v-if="rows.length === 0" class="no-values">No values recorded</div>
    <dl v-else class="breakdown-list">
      <div v-for="row in rows" :key="row.key" class="breakdown-row">
        <dt class="condition-label">{{ row.label }}</dt>
        <dd class="condition-value">{{ formatCurrency(row.value) }}</dd>
      </div>
    </dl>
  </div>
</template>

<style scoped>
.value-breakdown {
  font-size: 0.9rem;
}

.no-values {
  color: #888;
}

.breakdown-list {
  margin: 0;
  padding: 0;
}

.breakdown-row {
  display: flex;
  justify-content: space-between;
  padding: 0.35rem 0;
  border-bottom: 1px solid #f0f0f0;
}

.breakdown-row:last-child {
  border-bottom: none;
}

.condition-label {
  color: #555;
}

.condition-value {
  font-weight: 600;
  color: #1e1e2e;
  margin: 0;
}
</style>
