# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Friksi** is a next-generation civic engagement platform that combines Reddit-style discussions with democratic moderation, sophisticated anti-bot protection, and trust-based gamification. It's built as a Next.js 14+ application using TypeScript and Supabase.

## Common Development Commands

### Environment Setup

```bash
# Use Node.js 18 (required - see .nvmrc)
nvm use 18

# Install dependencies
pnpm install
```

### Development

```bash
# Start development server
pnpm dev

# Build for production
pnpm build

# Start production server
pnpm start
```

### Code Quality

```bash
# Lint code
pnpm lint

# Type check TypeScript
pnpm type-check

# Format code with Prettier
pnpm format

# Check formatting
pnpm format:check

# Clean build artifacts
pnpm clean
```

### Database Operations

```bash
# Generate TypeScript types from Supabase
pnpm db:types

# Apply schema changes to database
pnpm db:migrate

# Reset database (careful!)
pnpm db:reset

# Run database seeds
pnpm db:seed
```

### Testing

```bash
# Run tests (when implemented)
# Note: Test setup to be added
```

## Architecture Overview

This is a **Next.js 14+ application** using the App Router with the following structure:

### Application Structure

- **`src/app/`** - Next.js App Router pages and layouts
  - `(main)/` - Main user-facing pages (threads, categories)
  - `(auth)/` - Authentication pages (login, register, forgot-password)
  - `(admin)/` - Admin pages (planned for future)
  - `(moderator)/` - Moderator pages (planned for future)
  - `layout.tsx` - Root layout with providers
  - `page.tsx` - Homepage

- **`src/components/`** - React components
  - `ui/` - Reusable UI components (shadcn/ui + Radix UI)
  - `auth/` - Authentication components (LoginForm, RegisterForm, AuthGuard)
  - `layout/` - Layout components (Header, Navigation)
  - `threads/` - Thread/discussion components (ThreadList, ThreadDetail, CommentSection)
  - `misc/` - Miscellaneous components

- **`src/lib/`** - Utility libraries and integrations
  - `database/` - Supabase integration and database helpers
    - `lib/` - Client configurations (browser, server, auth, realtime)
    - `helpers/` - Database query helpers (threads, comments, users, votes)
    - `types/` - Generated TypeScript types from Supabase schema

- **`src/hooks/`** - Custom React hooks
  - `use-auth.tsx` - Authentication hook with context provider

- **`src/providers/`** - React context providers
  - `theme-provider.tsx` - Theme/dark mode provider

- **`supabase/`** - Database schema and migrations
  - `migrations/` - SQL migration files (versioned)
  - `schema.sql` - Complete database schema reference
  - `rls-policies.sql` - Row Level Security policies
  - `seed/` - Database seed files

- **`public/`** - Static assets
  - `manifest.json` - PWA manifest

## Key Technologies

### Core Stack

- **Frontend**: Next.js 14+ with App Router, TypeScript, Tailwind CSS
- **UI Components**: Mantine UI + shadcn/ui components
- **Backend**: Supabase (PostgreSQL with LTREE for threaded comments)
- **Real-time**: Supabase Realtime subscriptions
- **Authentication**: Supabase Auth
- **Package Management**: pnpm
- **Database**: PostgreSQL with LTREE extension

### Database Architecture

- **PostgreSQL with LTREE extension** for efficient nested comment threading
- **Row Level Security (RLS)** policies for data access control
- **Supabase** for backend-as-a-service with real-time capabilities

## Important Development Notes

### Environment Requirements

- **Node.js 18+** (specified in .nvmrc)
- **pnpm 8+** (specified in package.json engines)
- **Supabase CLI** (for local database development)

### Code Conventions

- **TypeScript** throughout the codebase
- **Tailwind CSS** for styling with Mantine/shadcn/ui component patterns
- **Path aliases** using `@/` for `src/` directory imports
- **Component patterns** follow shadcn/ui conventions with Radix UI primitives

### Database Development Workflow

1. Make schema changes in `supabase/migrations/`
2. Run `pnpm db:migrate` to apply changes
3. Run `pnpm db:types` to regenerate TypeScript types
4. Use generated types in application code via `@/lib/database`

### Component Development Workflow

1. Create components in appropriate directory under `src/components/`
2. Export from the component file
3. Import with path alias: `import { Component } from '@/components/category/Component'`

### Import Path Examples

```typescript
// Database types and helpers
import { ThreadHelpers, type Thread } from '@/lib/database'
import { FriksiAuth } from '@/lib/database'

// UI components
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'

// Auth components
import { AuthGuard } from '@/components/auth/AuthGuard'
import { useAuth } from '@/hooks/use-auth'

// Layout components
import { Header } from '@/components/layout/Header'
```

## Unique Platform Features

### Threading System

- **LTREE-based nested comments** for Reddit-style discussions
- **Real-time updates** via Supabase subscriptions
- **Wilson score intervals** for quality ranking

### Anti-Bot Protection

- **Three-layer detection system** with automatic classification
- **Trust-based user leveling** (Levels 1-5 with progressive privileges)
- **Democratic moderation** with community elections

### Gamification

- **5-level progression system**: Read → Post → Report → Create Polls → Moderate
- **Monthly voting sessions** with special badges
- **AI-powered daily summarization** of discussions (planned)

## Environment Files

```bash
# Required environment setup
cp .env.example .env.local

# Add Supabase credentials and other required variables
# See .env.example for complete list of required variables
```

### Required Environment Variables

```bash
NEXT_PUBLIC_SUPABASE_URL=          # Your Supabase project URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=     # Your Supabase anonymous key
SUPABASE_SERVICE_ROLE_KEY=         # Service role key (server-side only)
NEXT_PUBLIC_APP_URL=               # Application URL (http://localhost:3000 in dev)
```

## Supabase Integration

- Database schema stored in `supabase/schema.sql`
- RLS policies in `supabase/rls-policies.sql`
- Migrations in `supabase/migrations/`
- Seeds in `supabase/seed/`

### Database Helpers

The application uses typed helper classes for database operations:

- **ThreadHelpers** - Thread/post operations (`@/lib/database/helpers/threads`)
- **CommentHelpers** - Comment operations (`@/lib/database/helpers/comments`)
- **UserHelpers** - User profile operations (`@/lib/database/helpers/users`)
- **VoteHelpers** - Voting operations (`@/lib/database/helpers/votes`)

### Authentication

Authentication is handled through:
- **FriksiAuth** class - Client-side auth operations (`@/lib/database/lib/auth`)
- **ServerAuth** class - Server-side auth operations
- **useAuth** hook - React hook for auth state (`@/hooks/use-auth`)

## Project Structure Summary

```
friksi/
├── src/
│   ├── app/              # Next.js App Router pages
│   ├── components/       # React components
│   ├── lib/             # Utilities and database integration
│   ├── hooks/           # React hooks
│   └── providers/       # React context providers
├── supabase/            # Database schema and migrations
├── public/              # Static assets
├── .env.local           # Environment variables (not committed)
├── next.config.js       # Next.js configuration
├── tailwind.config.ts   # Tailwind CSS configuration
├── tsconfig.json        # TypeScript configuration
└── package.json         # Dependencies and scripts
```