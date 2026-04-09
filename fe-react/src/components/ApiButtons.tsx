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

export default function ApiButtons() {
  const restQuery = useRestAPI()
  const graphQLMutation = useGraphQLAPI('{ hello }')

  const handleRestClick = () => {
    restQuery.refetch()
  }

  const handleGraphQLClick = () => {
    graphQLMutation.mutate()
  }

  return (
    <div className="api-buttons">
      <h2>API Calls</h2>
      
      <div className="button-group">
        <button
          onClick={handleRestClick}
          disabled={restQuery.isLoading}
          className="api-button"
        >
          {restQuery.isLoading ? 'Loading...' : 'Call REST API'}
        </button>
        
        <button
          onClick={handleGraphQLClick}
          disabled={graphQLMutation.isPending}
          className="api-button"
        >
          {graphQLMutation.isPending ? 'Loading...' : 'Call GraphQL API'}
        </button>
      </div>

      {/* Print REST response */}
      {restQuery.data && (
        <div className="response">
          <h3>REST Response:</h3>
          <pre>{JSON.stringify(restQuery.data, null, 2)}</pre>
        </div>
      )}

      {restQuery.error && (
        <div className="error">
          <h3>REST Error:</h3>
          <pre>{String(restQuery.error)}</pre>
        </div>
      )}

      {/* Print GraphQL response */}
      {graphQLMutation.data && (
        <div className="response">
          <h3>GraphQL Response:</h3>
          <pre>{JSON.stringify(graphQLMutation.data, null, 2)}</pre>
        </div>
      )}

      {graphQLMutation.error && (
        <div className="error">
          <h3>GraphQL Error:</h3>
          <pre>{String(graphQLMutation.error)}</pre>
        </div>
      )}
    </div>
  )
}
