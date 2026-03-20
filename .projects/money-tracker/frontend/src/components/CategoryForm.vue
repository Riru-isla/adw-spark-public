<script setup lang="ts">
import { ref, watch } from 'vue'
import 'vanilla-colorful'
import type { Category, CategoryData } from '@/api/index'

const ICON_CHIPS = ['grocery', 'food', 'transport', 'health', 'entertainment', 'utilities', 'salary', 'savings']

const props = defineProps<{
  category?: Category
}>()

const emit = defineEmits<{
  submit: [data: CategoryData]
  cancel: []
}>()

const name = ref(props.category?.name ?? '')
const color = ref(props.category?.color ?? '#4f46e5')
const icon = ref(props.category?.icon ?? '')
const nameError = ref('')

watch(
  () => props.category,
  (cat) => {
    name.value = cat?.name ?? ''
    color.value = cat?.color ?? '#4f46e5'
    icon.value = cat?.icon ?? ''
    nameError.value = ''
  },
)

function onColorChange(e: Event) {
  const detail = (e as CustomEvent<{ value: string }>).detail
  if (detail?.value) color.value = detail.value
}

function selectIcon(chip: string) {
  icon.value = chip
}

function handleSubmit() {
  nameError.value = ''
  if (!name.value.trim()) {
    nameError.value = 'Name is required'
    return
  }
  emit('submit', { name: name.value.trim(), color: color.value, icon: icon.value })
}
</script>

<template>
  <form class="category-form" @submit.prevent="handleSubmit">
    <div class="field">
      <label for="cat-name">Name</label>
      <input id="cat-name" v-model="name" type="text" placeholder="Category name" />
      <span v-if="nameError" class="field-error">{{ nameError }}</span>
    </div>

    <div class="field">
      <label>Color</label>
      <div class="color-row">
        <hex-color-picker :color="color" @color-changed="onColorChange" />
        <span class="color-swatch" :style="{ background: color }" />
      </div>
      <input v-model="color" type="text" class="color-text" placeholder="#000000" />
    </div>

    <div class="field">
      <label for="cat-icon">Icon</label>
      <input id="cat-icon" v-model="icon" type="text" placeholder="e.g. shopping-cart" />
      <div class="icon-chips">
        <button
          v-for="chip in ICON_CHIPS"
          :key="chip"
          type="button"
          class="chip"
          :class="{ selected: icon === chip }"
          @click="selectIcon(chip)"
        >
          {{ chip }}
        </button>
      </div>
    </div>

    <div class="form-actions">
      <button type="button" class="btn-secondary" @click="emit('cancel')">Cancel</button>
      <button type="submit" class="btn-primary">{{ category ? 'Save' : 'Create' }}</button>
    </div>
  </form>
</template>

<style scoped>
.category-form {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

.field label {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-heading);
}

.field input[type='text'] {
  padding: 0.5rem 0.75rem;
  border: 1px solid var(--color-border);
  border-radius: 6px;
  background: var(--color-background);
  color: var(--color-text);
  font-size: 0.95rem;
}

.field-error {
  font-size: 0.8rem;
  color: #e53e3e;
}

.color-row {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
}

.color-swatch {
  display: inline-block;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: 2px solid var(--color-border);
  flex-shrink: 0;
  margin-top: 4px;
}

.color-text {
  width: 120px;
}

.icon-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
  margin-top: 0.25rem;
}

.chip {
  padding: 0.2rem 0.6rem;
  border: 1px solid var(--color-border);
  border-radius: 999px;
  background: var(--color-background-soft);
  color: var(--color-text);
  font-size: 0.8rem;
  cursor: pointer;
  transition: background-color 0.15s;
}

.chip:hover {
  background: var(--color-background-mute);
}

.chip.selected {
  background: var(--vt-c-indigo);
  color: #fff;
  border-color: var(--vt-c-indigo);
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
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

.btn-secondary {
  padding: 0.5rem 1.25rem;
  background: transparent;
  color: var(--color-text);
  border: 1px solid var(--color-border);
  border-radius: 6px;
  font-size: 0.95rem;
  cursor: pointer;
}
</style>
