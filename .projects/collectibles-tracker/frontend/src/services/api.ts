export async function apiFetch(path: string, options: RequestInit = {}): Promise<Response> {
  return fetch(`/api${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
  })
}

export async function getDashboard() {
  const response = await apiFetch('/dashboard')
  if (!response.ok) {
    throw new Error(`Failed to fetch dashboard: ${response.statusText}`)
  }
  return response.json()
}

export async function getCollections() {
  const response = await apiFetch('/collections')
  if (!response.ok) {
    throw new Error(`Failed to fetch collections: ${response.statusText}`)
  }
  return response.json()
}

export async function getCollection(id: number | string) {
  const response = await apiFetch(`/collections/${id}`)
  if (!response.ok) {
    throw new Error(`Failed to fetch collection: ${response.statusText}`)
  }
  return response.json()
}

export async function createCollection(data: { name: string; category?: string; description?: string }) {
  const response = await apiFetch('/collections', {
    method: 'POST',
    body: JSON.stringify({ collection: data }),
  })
  return response
}

export async function updateCollection(id: number, data: { name: string; category?: string; description?: string }) {
  const response = await apiFetch(`/collections/${id}`, {
    method: 'PATCH',
    body: JSON.stringify({ collection: data }),
  })
  return response
}

export async function deleteCollection(id: number) {
  const response = await apiFetch(`/collections/${id}`, {
    method: 'DELETE',
  })
  if (!response.ok) {
    throw new Error(`Failed to delete collection: ${response.statusText}`)
  }
}

export async function getItems(collectionId: number | string) {
  const response = await apiFetch(`/collections/${collectionId}/items`)
  if (!response.ok) {
    throw new Error(`Failed to fetch items: ${response.statusText}`)
  }
  return response.json()
}

export async function getItem(itemId: number | string) {
  const response = await apiFetch(`/items/${itemId}`)
  if (!response.ok) {
    throw new Error(`Failed to fetch item: ${response.statusText}`)
  }
  return response.json()
}

export async function createItem(collectionId: number | string, formData: FormData) {
  const response = await fetch(`/api/collections/${collectionId}/items`, {
    method: 'POST',
    body: formData,
  })
  return response
}

export async function updateItem(id: number | string, formData: FormData) {
  const response = await fetch(`/api/items/${id}`, {
    method: 'PATCH',
    body: formData,
  })
  return response
}

export interface SearchParams {
  query?: string
  collection_id?: number | string
  category?: string
  condition?: string
  value_min?: number | string
  value_max?: number | string
}

export async function searchItems(params: SearchParams) {
  const qs = Object.entries(params)
    .filter(([, v]) => v !== undefined && v !== '')
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
    .join('&')
  const response = await apiFetch(`/items/search${qs ? '?' + qs : ''}`)
  if (!response.ok) {
    throw new Error(`Failed to search items: ${response.statusText}`)
  }
  return response.json()
}

export async function deleteItem(id: number | string) {
  const response = await apiFetch(`/items/${id}`, {
    method: 'DELETE',
  })
  if (!response.ok) {
    throw new Error(`Failed to delete item: ${response.statusText}`)
  }
}
