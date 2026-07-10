const API_ENDPOINT = import.meta.env.VITE_API_ENDPOINT

if (!API_ENDPOINT) {
  throw new Error('Missing required env var: VITE_API_ENDPOINT')
}

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

export const getUploadUrl = async (filename: string, contentType: string = 'application/octet-stream') => {
  const token = await getAuthToken()

  const params = new URLSearchParams({ filename, contentType })
  const response = await fetch(`${API_ENDPOINT}/upload?${params}`, {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  })

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`)
  }

  return response.json() as Promise<{ url: string; key: string }>
}

export const uploadFile = async (file: File) => {
  const { url, key } = await getUploadUrl(file.name, file.type)

  const response = await fetch(url, {
    method: 'PUT',
    headers: {
      'Content-Type': file.type
    },
    body: file
  })

  if (!response.ok) {
    throw new Error(`Upload failed! status: ${response.status}`)
  }

  return { key, filename: file.name }
}
