import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Authenticator, ThemeProvider } from '@aws-amplify/ui-react'
import { Amplify } from 'aws-amplify'
import '@aws-amplify/ui-react/styles.css'
import awsConfig from './config/aws-exports'
import HomePage from './components/HomePage.tsx'
import './App.css'

// Configura AWS Amplify
Amplify.configure(awsConfig)

// Crea QueryClient per TanStack Query
const queryClient = new QueryClient()

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <Authenticator>
          {({ signOut, user }) => (
            <div className="app">
              <header>
                <h1>Learn AWS - Frontend</h1>
                <p>Welcome, {user?.username || 'User'}</p>
                <button onClick={signOut}>Sign Out</button>
              </header>
              
              <main>
                <HomePage />
              </main>
            </div>
          )}
        </Authenticator>
      </ThemeProvider>
    </QueryClientProvider>
  )
}

export default App
