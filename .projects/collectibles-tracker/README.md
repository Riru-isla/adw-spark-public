# Collectibles Vault

Track and organize your collectibles across multiple collections with photos, condition ratings, values, and searchable notes.

## Prerequisites

- [Docker](https://www.docker.com/) and Docker Compose
- Node.js 24+ (for local frontend development)
- Ruby 3.3.6 (for local backend development)

## Quick Start

```bash
cp .env.example .env
# Edit .env and set RAILS_MASTER_KEY (from backend/config/master.key)
docker-compose up
```

- Frontend: http://localhost:5173
- Backend API: http://localhost:3000
- Health check: http://localhost:3000/up

## Local Development

### Backend (Rails API)

```bash
cd backend
bundle install
bundle exec rails db:create db:migrate
bundle exec rails server
```

### Frontend (Vue 3 + Vite)

```bash
cd frontend
npm install
npm run dev
```

## Running Tests

### Backend

```bash
cd backend
bundle exec rspec
```

### Frontend

```bash
cd frontend
npm run test:unit
```

## Stack

- **Backend**: Ruby on Rails 8 (API mode), PostgreSQL
- **Frontend**: Vue 3, Vite, Pinia, Vue Router
- **Infrastructure**: Docker Compose
