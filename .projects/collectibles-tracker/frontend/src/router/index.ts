import { createRouter, createWebHistory } from 'vue-router'
import DashboardView from '../views/DashboardView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'dashboard',
      component: DashboardView,
    },
    {
      path: '/collections',
      name: 'collections',
      component: () => import('../views/CollectionsView.vue'),
    },
    {
      path: '/collections/:id',
      name: 'collection-detail',
      component: () => import('../views/CollectionDetailView.vue'),
    },
    {
      path: '/collections/:id/items/:itemId',
      name: 'item-detail',
      component: () => import('../views/ItemDetailView.vue'),
    },
    {
      path: '/search',
      name: 'search',
      component: () => import('../views/SearchView.vue'),
    },
  ],
})

export default router
