# Penny Pals

A friendly personal money tracker with budgets, colorful charts, and a reactive pet mascot that celebrates good spending habits.

## Prerequisites

- Docker & Docker Compose
- Ruby 3.3.6 (for local development)
- Node.js 22+ (for local development)

## Setup

```bash
cp .env.example .env
docker-compose up
```

The app will be available at:
- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:3000
- **Database**: localhost:5432

## Running Tests

**Backend (RSpec):**
```bash
cd backend
bundle exec rspec
```

**Frontend (Vitest):**
```bash
cd frontend
npm run test:unit
```

## Development

To run without Docker:

```bash
# Backend
cd backend
bundle install
bundle exec rails db:create db:migrate
bundle exec rails server

# Frontend (separate terminal)
cd frontend
npm install
npm run dev
```
