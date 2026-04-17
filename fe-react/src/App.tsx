import { useMutation } from '@tanstack/react-query'
import { Authenticator, ThemeProvider } from '@aws-amplify/ui-react'
import { Amplify } from 'aws-amplify'
import '@aws-amplify/ui-react/styles.css'
import awsConfig from './config/aws-exports'
import { fetchGraphQL } from './services/apiService'
import './App.css'

// Configura AWS Amplify
Amplify.configure(awsConfig)

// Hook per chiamata GraphQL API
const useGraphQLAPI = (query: string) => {
  return useMutation({
    mutationFn: () => fetchGraphQL(query)
  })
}

function App() {
  const graphQLMutation = useGraphQLAPI('{ getData { content timestamp } }')

  const handleGraphQLClick = () => {
    graphQLMutation.mutate()
  }

  return (
    <ThemeProvider>
      <Authenticator>
        {({ signOut, user }) => (
          <div className="app">
            <header>
              <h1>Learn AWS - Frontend</h1>
              <p>Welcome, {user?.username || 'User'}</p>
              <button onClick={signOut} className="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600">Sign Out</button>
            </header>
            
            <main>
              <div className="p-6">
                <h2 className="text-2xl font-bold mb-4">API Calls</h2>
                
                <div className="flex flex-col gap-4">
                    <button
                      onClick={handleGraphQLClick}
                      disabled={graphQLMutation.isPending}
                      className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {graphQLMutation.isPending ? 'Loading...' : 'Call GraphQL API'}
                    </button>
                    
                    {graphQLMutation.data && (
                      <div className="p-4 bg-green-50 border border-green-200 rounded">
                        <h3 className="text-lg font-semibold mb-2">GraphQL Response:</h3>
                        <pre className="whitespace-pre-wrap text-sm">{JSON.stringify(graphQLMutation.data, null, 2)}</pre>
                      </div>
                    )}

                    {graphQLMutation.error && (
                      <div className="p-4 bg-red-50 border border-red-200 rounded">
                        <h3 className="text-lg font-semibold mb-2">GraphQL Error:</h3>
                        <pre className="whitespace-pre-wrap text-sm">{String(graphQLMutation.error)}</pre>
                      </div>
                    )}
                  </div>
                </div>
            </main>
          </div>
        )}
      </Authenticator>
    </ThemeProvider>
  )
}

export default App
