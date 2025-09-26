'use client'

import { NavLink, Stack, Text } from '@mantine/core'
import {
  IconDashboard,
  IconUsers,
  IconCategory,
  IconChartBar,
  IconSettings,
} from '@tabler/icons-react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'

const adminNavItems = [
  { icon: IconDashboard, label: 'Dashboard', href: '/admin' },
  { icon: IconUsers, label: 'User Management', href: '/admin/users' },
  { icon: IconCategory, label: 'Categories', href: '/admin/categories' },
  { icon: IconChartBar, label: 'Analytics', href: '/admin/analytics' },
  { icon: IconSettings, label: 'System Settings', href: '/admin/settings' },
]

export function AdminNavigation() {
  const pathname = usePathname()

  return (
    <Stack gap="xs" p="md">
      <Text size="xs" tt="uppercase" fw={700} c="dimmed" mb="sm">
        Administration
      </Text>

      {adminNavItems.map(item => (
        <NavLink
          key={item.href}
          component={Link}
          href={item.href}
          label={item.label}
          leftSection={<item.icon size={16} />}
          active={pathname === item.href}
        />
      ))}
    </Stack>
  )
}
