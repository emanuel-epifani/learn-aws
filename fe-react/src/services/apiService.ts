// API Service per chiamate REST e GraphQL
// Questi URL verranno popolati dai Terraform outputs dopo il deploy

const REST_API_URL = import.meta.env.VITE_API_GATEWAY_URL || 'https://placeholder.execute-api.eu-north-1.amazonaws.com'
const GRAPHQL_API_URL = import.meta.env.VITE_APPSYNC_URL || 'https://placeholder.appsync-api.eu-north-1.amazonaws.com/graphql'

// Ottieni JWT token da Cognito
const getAuthToken = async (): Promise<string> => {
  try {
    const { fetchAuthSession } = await import('aws-amplify/auth')
    const session = await fetchAuthSession()
    const token = session.tokens?.idToken?.toString()
    if (!token) {
      throw new Error('No auth token available')
    }
    return token
  } catch (error) {
    console.error('Error getting auth token:', error)
    throw error
  }
}

// Chiamata REST API
export const fetchRestAPI = async (endpoint: string = '/data') => {
  try {
    const token = await getAuthToken()
    
    const response = await fetch(`${REST_API_URL}${endpoint}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const data = await response.json()
    return data
  } catch (error) {
    console.error('Error fetching REST API:', error)
    throw error
  }
}

// Chiamata GraphQL API
export const fetchGraphQL = async (query: string = '{ hello }') => {
  try {
    const token = await getAuthToken()
    
    const response = await fetch(GRAPHQL_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({ query })
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const data = await response.json()
    return data
  } catch (error) {
    console.error('Error fetching GraphQL API:', error)
    throw error
  }
}
