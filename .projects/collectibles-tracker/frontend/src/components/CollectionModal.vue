<script setup lang="ts">
import { ref, watch } from 'vue'
import { useCollectionsStore } from '@/stores/collections'
import type { Collection, CollectionFormData } from '@/stores/collections'

const props = defineProps<{
  collection?: Collection | null
  show: boolean
}>()

const emit = defineEmits<{
  close: []
  saved: []
}>()

const store = useCollectionsStore()

const name = ref('')
const category = ref('')
const description = ref('')
const saving = ref(false)
const fieldErrors = ref<string[]>([])
const generalError = ref<string | null>(null)

watch(
  () => [props.show, props.collection],
  () => {
    if (props.show) {
      name.value = props.collection?.name ?? ''
      category.value = props.collection?.category ?? ''
      description.value = props.collection?.description ?? ''
      fieldErrors.value = []
      generalError.value = null
    }
  },
  { immediate: true },
)

async function handleSubmit() {
  saving.value = true
  fieldErrors.value = []
  generalError.value = null

  const data: CollectionFormData = {
    name: name.value,
    category: category.value || undefined,
    description: description.value || undefined,
  }

  try {
    let errors: string[] | null
    if (props.collection) {
      errors = await store.updateCollection(props.collection.id, data)
    } else {
      errors = await store.createCollection(data)
    }

    if (errors) {
      fieldErrors.value = errors
    } else {
      emit('saved')
    }
  } catch (e) {
    generalError.value = e instanceof Error ? e.message : 'An error occurred'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div v-if="show" class="modal-backdrop" @click.self="emit('close')">
    <div class="modal">
      <h2 class="modal-title">{{ collection ? 'Edit Collection' : 'New Collection' }}</h2>

      <ul v-if="fieldErrors.length > 0" class="field-errors">
        <li v-for="err in fieldErrors" :key="err">{{ err }}</li>
      </ul>

      <div v-if="generalError" class="general-error">{{ generalError }}</div>

      <form @submit.prevent="handleSubmit">
        <div class="form-group">
          <label for="name">Name <span class="required">*</span></label>
          <input id="name" v-model="name" type="text" required />
        </div>
        <div class="form-group">
          <label for="category">Category</label>
          <input id="category" v-model="category" type="text" />
        </div>
        <div class="form-group">
          <label for="description">Description</label>
          <textarea id="description" v-model="description" rows="3" />
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-secondary" @click="emit('close')">Cancel</button>
          <button type="submit" class="btn-primary" :disabled="saving">
            {{ saving ? 'Saving…' : 'Save' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<style scoped>
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}

.modal {
  background: #fff;
  border-radius: 10px;
  padding: 2rem;
  width: 100%;
  max-width: 480px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.18);
}

.modal-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: #1e1e2e;
  margin-bottom: 1.25rem;
}

.field-errors {
  background: #fff0f0;
  border-radius: 6px;
  padding: 0.75rem 1rem;
  margin-bottom: 1rem;
  color: #d20f39;
  font-size: 0.875rem;
  list-style: disc inside;
}

.general-error {
  background: #fff0f0;
  border-radius: 6px;
  padding: 0.75rem 1rem;
  margin-bottom: 1rem;
  color: #d20f39;
  font-size: 0.875rem;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group label {
  display: block;
  font-size: 0.875rem;
  font-weight: 600;
  color: #1e1e2e;
  margin-bottom: 0.35rem;
}

.required {
  color: #d20f39;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 0.5rem 0.75rem;
  border: 1px solid #ccc;
  border-radius: 6px;
  font-size: 0.9rem;
  box-sizing: border-box;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  margin-top: 1.5rem;
}

.btn-primary {
  background: #1e66f5;
  color: #fff;
  border: none;
  border-radius: 6px;
  padding: 0.5rem 1.25rem;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-secondary {
  background: #eee;
  color: #333;
  border: none;
  border-radius: 6px;
  padding: 0.5rem 1.25rem;
  font-size: 0.9rem;
  cursor: pointer;
}
</style>
