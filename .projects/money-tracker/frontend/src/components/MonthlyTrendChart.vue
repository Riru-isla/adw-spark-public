<script setup lang="ts">
import { computed } from 'vue'
import { Line } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js'
import type { MonthlyTrendItem } from '@/api/index'

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler,
)

const props = defineProps<{
  monthlyTrend: MonthlyTrendItem[]
}>()

const chartData = computed(() => ({
  labels: props.monthlyTrend.map((item) => item.label),
  datasets: [
    {
      label: 'Spending',
      data: props.monthlyTrend.map((item) => item.total),
      borderColor: '#6366f1',
      backgroundColor: 'rgba(99, 102, 241, 0.15)',
      tension: 0.4,
      fill: true,
      pointBackgroundColor: '#6366f1',
    },
  ],
}))

const chartOptions = {
  responsive: true,
  maintainAspectRatio: true,
  scales: {
    y: {
      beginAtZero: true,
      ticks: {
        callback: (value: unknown) => `$${Number(value).toFixed(0)}`,
      },
    },
  },
  plugins: {
    legend: { display: false },
    tooltip: {
      callbacks: {
        label: (ctx: { raw: unknown }) => `$${Number(ctx.raw).toFixed(2)}`,
      },
    },
  },
}
</script>

<template>
  <div class="chart-container">
    <Line :data="chartData" :options="chartOptions" />
  </div>
</template>

<style scoped>
.chart-container {
  width: 100%;
}
</style>
