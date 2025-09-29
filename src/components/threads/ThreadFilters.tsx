'use client'

import { Group, Select } from '@mantine/core'
import { useRouter, useSearchParams } from 'next/navigation'
import type { Category } from '@/lib/database/helpers/categories'

interface ThreadFiltersProps {
  categories: Category[]
  currentSort: string
  currentCategory: string
}

export function ThreadFilters({ categories, currentSort, currentCategory }: ThreadFiltersProps) {
  const router = useRouter()
  const searchParams = useSearchParams()

  const handleSortChange = (value: string | null) => {
    if (!value) return

    const params = new URLSearchParams(searchParams.toString())
    params.set('sort', value)
    router.push(`/threads?${params.toString()}`)
  }

  const handleCategoryChange = (value: string | null) => {
    if (!value) return

    const params = new URLSearchParams(searchParams.toString())
    if (value === 'all') {
      params.delete('category')
    } else {
      params.set('category', value)
    }
    router.push(`/threads?${params.toString()}`)
  }

  const categoryOptions = [
    { value: 'all', label: 'All Categories' },
    ...categories.map(category => ({
      value: category.id,
      label: category.name
    }))
  ]

  return (
    <Group mb="lg">
      <Select
        placeholder="Sort by"
        data={[
          { value: 'hot', label: 'Hot' },
          { value: 'new', label: 'New' },
          { value: 'top', label: 'Top' },
          { value: 'controversial', label: 'Controversial' },
        ]}
        value={currentSort}
        onChange={handleSortChange}
      />
      <Select
        placeholder="Filter by category"
        data={categoryOptions}
        value={currentCategory}
        onChange={handleCategoryChange}
      />
    </Group>
  )
}