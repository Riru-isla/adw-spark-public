<script setup lang="ts">
import { ref, watch } from 'vue'
import { useItemsStore } from '@/stores/items'
import type { Item, Photo } from '@/stores/items'

const props = defineProps<{
  item?: Item | null
  collectionId: number
  show: boolean
}>()

const emit = defineEmits<{
  close: []
  saved: []
}>()

const itemsStore = useItemsStore()

const CONDITIONS = [
  { value: 'mint', label: 'Mint' },
  { value: 'near_mint', label: 'Near Mint' },
  { value: 'good', label: 'Good' },
  { value: 'fair', label: 'Fair' },
  { value: 'poor', label: 'Poor' },
]

const name = ref('')
const condition = ref('mint')
const estimatedValue = ref('')
const acquisitionDate = ref('')
const notes = ref('')
const saving = ref(false)
const fieldErrors = ref<string[]>([])
const generalError = ref<string | null>(null)

// New photo files selected
const newPhotoFiles = ref<File[]>([])
const newPhotoPreviews = ref<string[]>([])

// Existing photos (edit mode)
const existingPhotos = ref<Photo[]>([])
const removedPhotoIds = ref<number[]>([])

function resetForm() {
  if (props.item) {
    name.value = props.item.name
    condition.value = props.item.condition
    estimatedValue.value = props.item.estimated_value != null ? String(props.item.estimated_value) : ''
    acquisitionDate.value = props.item.acquisition_date ?? ''
    notes.value = props.item.notes ?? ''
    existingPhotos.value = [...(props.item.photos ?? [])]
    removedPhotoIds.value = []
  } else {
    name.value = ''
    condition.value = 'mint'
    estimatedValue.value = ''
    acquisitionDate.value = ''
    notes.value = ''
    existingPhotos.value = []
    removedPhotoIds.value = []
  }
  newPhotoFiles.value = []
  newPhotoPreviews.value.forEach((url) => URL.revokeObjectURL(url))
  newPhotoPreviews.value = []
  fieldErrors.value = []
  generalError.value = null
}

watch(
  () => [props.show, props.item],
  () => {
    if (props.show) resetForm()
  },
  { immediate: true },
)

function handleFileChange(event: Event) {
  const input = event.target as HTMLInputElement
  if (!input.files) return
  const files = Array.from(input.files)
  newPhotoFiles.value.push(...files)
  files.forEach((file) => {
    newPhotoPreviews.value.push(URL.createObjectURL(file))
  })
  input.value = ''
}

function removeExistingPhoto(photo: Photo) {
  existingPhotos.value = existingPhotos.value.filter((p) => p.id !== photo.id)
  removedPhotoIds.value.push(photo.id)
}

function removeNewPhoto(index: number) {
  URL.revokeObjectURL(newPhotoPreviews.value[index])
  newPhotoPreviews.value.splice(index, 1)
  newPhotoFiles.value.splice(index, 1)
}

async function handleSubmit() {
  saving.value = true
  fieldErrors.value = []
  generalError.value = null

  const formData = new FormData()
  formData.append('item[name]', name.value)
  formData.append('item[condition]', condition.value)
  if (estimatedValue.value !== '') formData.append('item[estimated_value]', estimatedValue.value)
  if (acquisitionDate.value !== '') formData.append('item[acquisition_date]', acquisitionDate.value)
  if (notes.value !== '') formData.append('item[notes]', notes.value)
  newPhotoFiles.value.forEach((file) => formData.append('item[photos][]', file))
  removedPhotoIds.value.forEach((id) => formData.append('item[remove_photo_ids][]', String(id)))

  try {
    let errors: string[] | null
    if (props.item) {
      errors = await itemsStore.updateItem(props.item.id, formData)
    } else {
      errors = await itemsStore.createItem(props.collectionId, formData)
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
      <h2 class="modal-title">{{ item ? 'Edit Item' : 'New Item' }}</h2>

      <ul v-if="fieldErrors.length > 0" class="field-errors">
        <li v-for="err in fieldErrors" :key="err">{{ err }}</li>
      </ul>

      <div v-if="generalError" class="general-error">{{ generalError }}</div>

      <form @submit.prevent="handleSubmit">
        <div class="form-group">
          <label for="item-name">Name <span class="required">*</span></label>
          <input id="item-name" v-model="name" type="text" required />
        </div>

        <div class="form-group">
          <label for="item-condition">Condition</label>
          <select id="item-condition" v-model="condition">
            <option v-for="opt in CONDITIONS" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
          </select>
        </div>

        <div class="form-group">
          <label for="item-estimated-value">Estimated Value</label>
          <input id="item-estimated-value" v-model="estimatedValue" type="number" step="0.01" min="0" />
        </div>

        <div class="form-group">
          <label for="item-acquisition-date">Acquisition Date</label>
          <input id="item-acquisition-date" v-model="acquisitionDate" type="date" />
        </div>

        <div class="form-group">
          <label for="item-notes">Notes</label>
          <textarea id="item-notes" v-model="notes" rows="3" />
        </div>

        <div class="form-group">
          <label>Photos</label>
          <input type="file" multiple accept="image/*" @change="handleFileChange" />

          <div v-if="existingPhotos.length > 0 || newPhotoPreviews.length > 0" class="photo-grid">
            <div v-for="photo in existingPhotos" :key="photo.id" class="photo-thumb">
              <img :src="photo.url" :alt="photo.filename" />
              <button type="button" class="remove-photo" @click="removeExistingPhoto(photo)">×</button>
            </div>
            <div v-for="(preview, index) in newPhotoPreviews" :key="preview" class="photo-thumb photo-thumb--new">
              <img :src="preview" alt="New photo preview" />
              <button type="button" class="remove-photo" @click="removeNewPhoto(index)">×</button>
            </div>
          </div>
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
  max-width: 520px;
  max-height: 90vh;
  overflow-y: auto;
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
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 0.5rem 0.75rem;
  border: 1px solid #ccc;
  border-radius: 6px;
  font-size: 0.9rem;
  box-sizing: border-box;
}

.photo-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-top: 0.5rem;
}

.photo-thumb {
  position: relative;
  width: 80px;
  height: 80px;
}

.photo-thumb img {
  width: 80px;
  height: 80px;
  object-fit: cover;
  border-radius: 6px;
}

.remove-photo {
  position: absolute;
  top: 2px;
  right: 2px;
  background: rgba(0, 0, 0, 0.6);
  color: #fff;
  border: none;
  border-radius: 50%;
  width: 20px;
  height: 20px;
  font-size: 14px;
  line-height: 1;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
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
