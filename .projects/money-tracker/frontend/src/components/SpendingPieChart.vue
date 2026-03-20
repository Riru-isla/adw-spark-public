<script setup lang="ts">
import { computed } from 'vue'
import { Pie } from 'vue-chartjs'
import { Chart as ChartJS, ArcElement, Tooltip, Legend } from 'chart.js'
import type { CategoryBreakdownItem } from '@/api/index'

ChartJS.register(ArcElement, Tooltip, Legend)

const props = defineProps<{
  categoryBreakdown: CategoryBreakdownItem[]
}>()

const chartData = computed(() => ({
  labels: props.categoryBreakdown.map((item) => item.category),
  datasets: [
    {
      data: props.categoryBreakdown.map((item) => item.spent),
      backgroundColor: props.categoryBreakdown.map((item) => item.color),
      borderWidth: 2,
      borderColor: '#fff',
    },
  ],
}))

const chartOptions = {
  responsive: true,
  maintainAspectRatio: true,
  plugins: {
    legend: {
      position: 'bottom' as const,
    },
    tooltip: {
      callbacks: {
        label: (ctx: { label: string; raw: unknown }) =>
          `${ctx.label}: $${Number(ctx.raw).toFixed(2)}`,
      },
    },
  },
}
</script>

<template>
  <div class="chart-container">
    <div v-if="categoryBreakdown.length === 0" class="empty-state">
      No expense transactions this month yet.
    </div>
    <Pie v-else :data="chartData" :options="chartOptions" />
  </div>
</template>

<style scoped>
.chart-container {
  width: 100%;
  max-width: 320px;
  margin: 0 auto;
}

.empty-state {
  text-align: center;
  color: var(--color-text);
  opacity: 0.6;
  padding: 2rem 0;
  font-size: 0.9rem;
}
</style>
