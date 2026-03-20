<template>
  <div id="app-layout">
    <nav class="sidebar">
      <div class="nav-brand">Collectibles</div>
      <ul class="nav-links">
        <li>
          <RouterLink to="/" exact-active-class="active">Dashboard</RouterLink>
        </li>
        <li>
          <RouterLink to="/collections" active-class="active">Collections</RouterLink>
        </li>
        <li>
          <RouterLink to="/search" active-class="active">Search</RouterLink>
        </li>
      </ul>
    </nav>
    <main class="main-content">
      <RouterView />
    </main>
  </div>
</template>

<style>
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: system-ui, -apple-system, sans-serif;
  background: #f5f5f5;
  color: #333;
}

#app-layout {
  display: flex;
  min-height: 100vh;
}

.sidebar {
  width: 200px;
  background: #1e1e2e;
  color: #cdd6f4;
  padding: 1.5rem 0;
  flex-shrink: 0;
}

.nav-brand {
  font-size: 1.2rem;
  font-weight: 700;
  padding: 0 1.25rem 1.5rem;
  color: #cba6f7;
  border-bottom: 1px solid #313244;
}

.nav-links {
  list-style: none;
  padding: 1rem 0;
}

.nav-links li a {
  display: block;
  padding: 0.6rem 1.25rem;
  color: #bac2de;
  text-decoration: none;
  transition: background 0.15s, color 0.15s;
}

.nav-links li a:hover {
  background: #313244;
  color: #cdd6f4;
}

.nav-links li a.active {
  background: #313244;
  color: #cba6f7;
  font-weight: 600;
}

.main-content {
  flex: 1;
  padding: 2rem;
  overflow-y: auto;
}
</style>
