import { useState } from 'react'
import { Authenticator, ThemeProvider } from '@aws-amplify/ui-react'
import { Amplify } from 'aws-amplify'
import '@aws-amplify/ui-react/styles.css'
import awsConfig from './config/aws-exports'
import ServerlessPage from './pages/ServerlessPage'
import ContainerPage from './pages/ContainerPage'
import './App.css'

Amplify.configure(awsConfig)

type Page = 'serverless' | 'container'

function App() {
  const [activePage, setActivePage] = useState<Page>('serverless')

  const navItems: { key: Page; label: string; sublabel: string }[] = [
    { key: 'serverless', label: 'Serverless', sublabel: 'API Gateway + Lambda + S3' },
    { key: 'container', label: 'ECS Fargate', sublabel: 'ALB + ECS + RDS' }
  ]

  return (
    <ThemeProvider>
      <Authenticator>
        {({ signOut, user }) => (
          <div className="app flex h-screen">
            <aside className="w-64 bg-gray-900 text-white flex flex-col shrink-0">
              <div className="p-4 border-b border-gray-700">
                <h1 className="text-lg font-bold">Learn AWS</h1>
                <p className="text-sm text-gray-400">{user?.username}</p>
              </div>

              <nav className="flex-1 p-2">
                {navItems.map((item) => (
                  <button
                    key={item.key}
                    onClick={() => setActivePage(item.key)}
                    className={`w-full text-left px-4 py-3 rounded mb-1 transition ${
                      activePage === item.key
                        ? 'bg-blue-600 text-white'
                        : 'text-gray-300 hover:bg-gray-800'
                    }`}
                  >
                    <p className="font-semibold text-sm">{item.label}</p>
                    <p className="text-xs text-gray-400">{item.sublabel}</p>
                  </button>
                ))}
              </nav>

              <div className="p-4 border-t border-gray-700">
                <button
                  onClick={signOut}
                  className="w-full px-4 py-2 bg-red-500 text-white text-sm rounded hover:bg-red-600"
                >
                  Sign Out
                </button>
              </div>
            </aside>

            <main className="flex-1 overflow-auto bg-gray-50">
              {activePage === 'serverless' && <ServerlessPage />}
              {activePage === 'container' && <ContainerPage />}
            </main>
          </div>
        )}
      </Authenticator>
    </ThemeProvider>
  )
}

export default App
