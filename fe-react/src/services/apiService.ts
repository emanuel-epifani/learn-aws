const API_ENDPOINT = import.meta.env.VITE_API_ENDPOINT

if (!API_ENDPOINT) {
  throw new Error('Missing required env var: VITE_API_ENDPOINT')
}

const ALB_ENDPOINT = import.meta.env.VITE_ALB_ENDPOINT

if (!ALB_ENDPOINT) {
  throw new Error('Missing required env var: VITE_ALB_ENDPOINT')
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

export type FileItem = {
  key: string
  size: number
  lastModified: string
}

export const listFiles = async () => {
  const token = await getAuthToken()

  const response = await fetch(`${API_ENDPOINT}/files`, {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  })

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`)
  }

  return response.json() as Promise<{ files: FileItem[] }>
}

export const downloadFile = async (key: string) => {
  const token = await getAuthToken()

  const response = await fetch(`${API_ENDPOINT}/files/${encodeURIComponent(key)}/download`, {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  })

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`)
  }

  return response.json() as Promise<{ url: string }>
}

export const deleteFile = async (key: string) => {
  const token = await getAuthToken()

  const response = await fetch(`${API_ENDPOINT}/files/${encodeURIComponent(key)}`, {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  })

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`)
  }

  return response.json() as Promise<{ deleted: boolean; key: string }>
}

export type Note = {
  id: number
  title: string
  content: string
  created_at: string
}

export const listNotes = async () => {
  const token = await getAuthToken()

  const response = await fetch(`${ALB_ENDPOINT}/api/notes`, {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  })

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`)
  }

  return response.json() as Promise<{ notes: Note[] }>
}

export const createNote = async (title: string, content: string) => {
  const token = await getAuthToken()

  const response = await fetch(`${ALB_ENDPOINT}/api/notes`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ title, content })
  })

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`)
  }

  return response.json() as Promise<{ note: Note }>
}

export const deleteNote = async (id: number) => {
  const token = await getAuthToken()

  const response = await fetch(`${ALB_ENDPOINT}/api/notes/${id}`, {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  })

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`)
  }

  return response.json() as Promise<{ deleted: boolean; id: number }>
}
