'use client'

import { NavLink, Stack, Text } from '@mantine/core'
import {
  IconDashboard,
  IconFlag,
  IconRobot,
  IconList,
  IconCategory,
} from '@tabler/icons-react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'

const moderatorNavItems = [
  { icon: IconDashboard, label: 'Dashboard', href: '/moderate' },
  { icon: IconList, label: 'Moderation Queue', href: '/moderate/queue' },
  { icon: IconFlag, label: 'Reports', href: '/moderate/reports' },
  { icon: IconRobot, label: 'Bot Detection', href: '/moderate/bots' },
  { icon: IconCategory, label: 'My Categories', href: '/moderate/categories' },
]

export function ModeratorNavigation() {
  const pathname = usePathname()

  return (
    <Stack gap="xs" p="md">
      <Text size="xs" tt="uppercase" fw={700} c="dimmed" mb="sm">
        Moderation Tools
      </Text>

      {moderatorNavItems.map(item => (
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
