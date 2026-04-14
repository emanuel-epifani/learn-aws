import { useQuery, useMutation } from '@tanstack/react-query'
import { fetchRestAPI, fetchGraphQL } from '../services/apiService'

// Hook per chiamata REST API
const useRestAPI = () => {
  return useQuery({
    queryKey: ['restAPI'],
    queryFn: () => fetchRestAPI('/data'),
    enabled: false // Non chiamare automaticamente
  })
}

// Hook per chiamata GraphQL API
const useGraphQLAPI = (query: string) => {
  return useMutation({
    mutationFn: () => fetchGraphQL(query)
  })
}

export default function HomePage() {
  const restQuery = useRestAPI()
  const graphQLMutation = useGraphQLAPI('{ hello }')

  const handleRestClick = () => {
    restQuery.refetch()
  }

  const handleGraphQLClick = () => {
    graphQLMutation.mutate()
  }

  return (
    <div className="p-6">
      <h2 className="text-2xl font-bold mb-4">API Calls</h2>
      
      <div className="grid grid-cols-2 gap-6">
        {/* Left column: REST API */}
        <div className="flex flex-col gap-4">
          <button
            onClick={handleRestClick}
            disabled={restQuery.isLoading}
            className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {restQuery.isLoading ? 'Loading...' : 'Call REST API'}
          </button>
          
          {restQuery.data && (
            <div className="p-4 bg-green-50 border border-green-200 rounded">
              <h3 className="text-lg font-semibold mb-2">REST Response:</h3>
              <pre className="whitespace-pre-wrap text-sm">{JSON.stringify(restQuery.data, null, 2)}</pre>
            </div>
          )}

          {restQuery.error && (
            <div className="p-4 bg-red-50 border border-red-200 rounded">
              <h3 className="text-lg font-semibold mb-2">REST Error:</h3>
              <pre className="whitespace-pre-wrap text-sm">{String(restQuery.error)}</pre>
            </div>
          )}
        </div>

        {/* Right column: GraphQL API */}
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
    </div>
  )
}
