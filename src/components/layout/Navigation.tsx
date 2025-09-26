'use client'

import { NavLink, Stack, Group, Text, Badge } from '@mantine/core'
import {
  IconHome,
  IconMessage,
  IconCategory,
  IconUsers,
  IconTrophy,
  IconThumbUp,
  IconSettings,
  IconShield,
} from '@tabler/icons-react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useAuth } from '@/hooks/use-auth'

const mainNavItems = [
  { icon: IconHome, label: 'Home', href: '/' },
  { icon: IconMessage, label: 'Discussions', href: '/threads' },
  { icon: IconCategory, label: 'Categories', href: '/category' },
  { icon: IconUsers, label: 'Community', href: '/users' },
  { icon: IconTrophy, label: 'Leaderboard', href: '/leaderboard' },
  { icon: IconThumbUp, label: 'Elections', href: '/elections', badge: '2' },
]

const userNavItems = [
  { icon: IconSettings, label: 'Settings', href: '/settings' },
]

export function Navigation() {
  const pathname = usePathname()
  const { user } = useAuth()

  return (
    <Stack gap="xs" p="md">
      <Text size="xs" tt="uppercase" fw={700} c="dimmed" mb="sm">
        Main
      </Text>

      {mainNavItems.map(item => (
        <NavLink
          key={item.href}
          component={Link}
          href={item.href}
          label={item.label}
          leftSection={<item.icon size={16} />}
          rightSection={
            item.badge ? (
              <Badge size="xs" color="red">
                {item.badge}
              </Badge>
            ) : null
          }
          active={pathname === item.href}
        />
      ))}

      {user && (
        <>
          <Text size="xs" tt="uppercase" fw={700} c="dimmed" mb="sm" mt="lg">
            Personal
          </Text>

          {userNavItems.map(item => (
            <NavLink
              key={item.href}
              component={Link}
              href={item.href}
              label={item.label}
              leftSection={<item.icon size={16} />}
              active={pathname === item.href}
            />
          ))}

          {user.level >= 3 && (
            <NavLink
              component={Link}
              href="/moderate"
              label="Moderation"
              leftSection={<IconShield size={16} />}
              active={pathname.startsWith('/moderate')}
            />
          )}
        </>
      )}

      {user && (
        <>
          <Text size="xs" tt="uppercase" fw={700} c="dimmed" mb="sm" mt="lg">
            User Level {user.level}
          </Text>

          <Group gap="xs">
            <Text size="xs" c="dimmed">
              XP: {user.xp}
            </Text>
            <Text size="xs" c="dimmed">
              Trust: {user.trust_score}%
            </Text>
          </Group>
        </>
      )}
    </Stack>
  )
}
