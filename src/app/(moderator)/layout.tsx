import { AppShell } from '@mantine/core'
import { Header } from '@/components/layout/Header'
import { ModeratorNavigation } from '@/components/layout/ModeratorNavigation'
import { AuthGuard } from '@/components/auth/AuthGuard'

export default function ModeratorLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <AuthGuard requireModerator>
      <AppShell
        header={{ height: 60 }}
        navbar={{
          width: 280,
          breakpoint: 'sm',
          collapsed: { mobile: true },
        }}
        padding="md"
      >
        <AppShell.Header>
          <Header />
        </AppShell.Header>

        <AppShell.Navbar>
          <ModeratorNavigation />
        </AppShell.Navbar>

        <AppShell.Main>{children}</AppShell.Main>
      </AppShell>
    </AuthGuard>
  )
}
