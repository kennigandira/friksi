'use client'

import {
  Group,
  Text,
  UnstyledButton,
  Avatar,
  Menu,
  Burger,
  ActionIcon,
  useMantineTheme,
} from '@mantine/core'
import {
  IconUser,
  IconSettings,
  IconLogout,
  IconBell,
  IconSun,
  IconMoon,
} from '@tabler/icons-react'
import { useDisclosure, useColorScheme } from '@mantine/hooks'
import Link from 'next/link'
import { useAuth } from '@/hooks/use-auth'

export function Header() {
  const [opened, { toggle }] = useDisclosure()
  const { user, logout } = useAuth()
  const { colorScheme, toggleColorScheme } = useColorScheme()
  const theme = useMantineTheme()

  return (
    <Group h="100%" px="md" justify="space-between">
      <Group>
        <Burger opened={opened} onClick={toggle} hiddenFrom="sm" size="sm" />

        <Text
          component={Link}
          href="/"
          size="xl"
          fw={700}
          c="blue"
          style={{ textDecoration: 'none' }}
        >
          Friksi
        </Text>
      </Group>

      <Group>
        <ActionIcon
          variant="subtle"
          onClick={() => toggleColorScheme()}
          size="lg"
        >
          {colorScheme === 'dark' ? (
            <IconSun size={18} />
          ) : (
            <IconMoon size={18} />
          )}
        </ActionIcon>

        {user ? (
          <>
            <ActionIcon variant="subtle" size="lg">
              <IconBell size={18} />
            </ActionIcon>

            <Menu shadow="md" width={200}>
              <Menu.Target>
                <UnstyledButton>
                  <Group gap="xs">
                    <Avatar size="sm" src={user.avatar_url} />
                    <Text size="sm" fw={500}>
                      {user.username}
                    </Text>
                  </Group>
                </UnstyledButton>
              </Menu.Target>

              <Menu.Dropdown>
                <Menu.Item
                  component={Link}
                  href={`/user/${user.username}`}
                  leftSection={<IconUser size={14} />}
                >
                  Profile
                </Menu.Item>

                <Menu.Item
                  component={Link}
                  href="/settings"
                  leftSection={<IconSettings size={14} />}
                >
                  Settings
                </Menu.Item>

                <Menu.Divider />

                <Menu.Item
                  leftSection={<IconLogout size={14} />}
                  onClick={logout}
                >
                  Logout
                </Menu.Item>
              </Menu.Dropdown>
            </Menu>
          </>
        ) : (
          <Group>
            <UnstyledButton component={Link} href="/login">
              <Text size="sm" fw={500}>
                Login
              </Text>
            </UnstyledButton>

            <UnstyledButton component={Link} href="/register">
              <Text size="sm" fw={500} c="blue">
                Sign Up
              </Text>
            </UnstyledButton>
          </Group>
        )}
      </Group>
    </Group>
  )
}
