import { AppShell } from '@mantine/core'
import { Header } from '@/components/layout/Header'
import { Navigation } from '@/components/layout/Navigation'

export default function MainLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <AppShell
      header={{ height: 60 }}
      navbar={{
        width: 300,
        breakpoint: 'sm',
        collapsed: { mobile: true },
      }}
      padding="md"
    >
      <AppShell.Header>
        <Header />
      </AppShell.Header>

      <AppShell.Navbar>
        <Navigation />
      </AppShell.Navbar>

      <AppShell.Main>{children}</AppShell.Main>
    </AppShell>
  )
}
