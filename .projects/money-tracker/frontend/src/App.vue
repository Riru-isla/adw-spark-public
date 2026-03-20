<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'
</script>

<template>
  <div class="app-layout">
    <nav class="sidebar">
      <div class="sidebar-header">
        <span class="app-name">Money Tracker</span>
      </div>
      <ul class="nav-links">
        <li>
          <RouterLink to="/" active-class="active" exact-active-class="active">Dashboard</RouterLink>
        </li>
        <li>
          <RouterLink to="/transactions" active-class="active">Transactions</RouterLink>
        </li>
        <li>
          <RouterLink to="/categories" active-class="active">Categories</RouterLink>
        </li>
        <li>
          <RouterLink to="/budgets" active-class="active">Budgets</RouterLink>
        </li>
      </ul>
    </nav>
    <main class="main-content">
      <RouterView />
    </main>
  </div>
</template>

<style scoped>
.app-layout {
  display: flex;
  min-height: 100vh;
}

.sidebar {
  width: 220px;
  flex-shrink: 0;
  background: var(--color-background-soft);
  border-right: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
  padding: 0;
}

.sidebar-header {
  padding: 1.5rem 1.25rem 1rem;
  border-bottom: 1px solid var(--color-border);
}

.app-name {
  font-size: 1.1rem;
  font-weight: 600;
  color: var(--color-heading);
}

.nav-links {
  list-style: none;
  padding: 0.75rem 0;
  margin: 0;
}

.nav-links li a {
  display: block;
  padding: 0.6rem 1.25rem;
  color: var(--color-text);
  text-decoration: none;
  font-size: 0.95rem;
  border-left: 3px solid transparent;
  transition:
    background-color 0.15s,
    border-color 0.15s;
}

.nav-links li a:hover {
  background: var(--color-background-mute);
}

.nav-links li a.active {
  border-left-color: var(--vt-c-indigo);
  color: var(--color-heading);
  font-weight: 500;
  background: var(--color-background-mute);
}

.main-content {
  flex: 1;
  padding: 2rem;
  overflow-y: auto;
}
</style>
