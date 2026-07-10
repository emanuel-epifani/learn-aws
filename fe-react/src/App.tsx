import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Authenticator, ThemeProvider } from '@aws-amplify/ui-react'
import { Amplify } from 'aws-amplify'
import '@aws-amplify/ui-react/styles.css'
import awsConfig from './config/aws-exports'
import { uploadFile, listFiles, downloadFile, deleteFile, listNotes, createNote, deleteNote } from './services/apiService'
import './App.css'

Amplify.configure(awsConfig)

function App() {
  const queryClient = useQueryClient()
  const [noteTitle, setNoteTitle] = useState('')
  const [noteContent, setNoteContent] = useState('')

  const { data: filesData, isLoading: filesLoading } = useQuery({
    queryKey: ['files'],
    queryFn: listFiles
  })

  const { data: notesData, isLoading: notesLoading } = useQuery({
    queryKey: ['notes'],
    queryFn: listNotes
  })

  const uploadMutation = useMutation({
    mutationFn: (file: File) => uploadFile(file),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['files'] })
  })

  const deleteFileMutation = useMutation({
    mutationFn: (key: string) => deleteFile(key),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['files'] })
  })

  const createNoteMutation = useMutation({
    mutationFn: ({ title, content }: { title: string; content: string }) => createNote(title, content),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notes'] })
      setNoteTitle('')
      setNoteContent('')
    }
  })

  const deleteNoteMutation = useMutation({
    mutationFn: (id: number) => deleteNote(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notes'] })
  })

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      uploadMutation.mutate(file)
    }
  }

  const handleDownload = async (key: string) => {
    const { url } = await downloadFile(key)
    window.open(url, '_blank')
  }

  const handleSaveNote = () => {
    if (noteTitle && noteContent) {
      createNoteMutation.mutate({ title: noteTitle, content: noteContent })
    }
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

            <main className="flex gap-8 p-6">
              {/* Note Manager (container stack) */}
              <div className="flex-1">
                <h2 className="text-2xl font-bold mb-4">Note Manager</h2>

                <div className="flex flex-col gap-4">
                  <input
                    type="text"
                    placeholder="Title"
                    value={noteTitle}
                    onChange={(e) => setNoteTitle(e.target.value)}
                    className="px-4 py-2 border rounded"
                  />
                  <textarea
                    placeholder="Content"
                    value={noteContent}
                    onChange={(e) => setNoteContent(e.target.value)}
                    rows={4}
                    className="px-4 py-2 border rounded"
                  />
                  <button
                    onClick={handleSaveNote}
                    disabled={createNoteMutation.isPending || !noteTitle || !noteContent}
                    className="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600 disabled:opacity-50"
                  >
                    {createNoteMutation.isPending ? 'Saving...' : 'Save Note'}
                  </button>

                  {createNoteMutation.error && (
                    <div className="p-4 bg-red-50 border border-red-200 rounded">
                      <pre className="whitespace-pre-wrap text-sm">{String(createNoteMutation.error)}</pre>
                    </div>
                  )}

                  <div>
                    <h3 className="text-lg font-semibold mb-2">My notes</h3>

                    {notesLoading && <p className="text-gray-500">Loading...</p>}

                    {notesData?.notes?.length === 0 && (
                      <p className="text-gray-500">No notes yet.</p>
                    )}

                    {notesData?.notes?.length > 0 && (
                      <ul className="divide-y divide-gray-200 border rounded">
                        {notesData.notes.map((note) => (
                          <li key={note.id} className="flex items-center justify-between px-4 py-2">
                            <div className="flex-1 mr-2">
                              <p className="font-semibold text-sm">{note.title}</p>
                              <p className="text-sm text-gray-600 truncate">{note.content}</p>
                            </div>
                            <button
                              onClick={() => deleteNoteMutation.mutate(note.id)}
                              disabled={deleteNoteMutation.isPending}
                              className="px-3 py-1 bg-red-500 text-white text-sm rounded hover:bg-red-600 disabled:opacity-50"
                            >
                              Delete
                            </button>
                          </li>
                        ))}
                      </ul>
                    )}
                  </div>
                </div>
              </div>

              {/* File Bin (serverless stack) */}
              <div className="flex-1">
                <h2 className="text-2xl font-bold mb-4">File Bin</h2>

                <div className="flex flex-col gap-4">
                  <input
                    type="file"
                    onChange={handleFileChange}
                    disabled={uploadMutation.isPending}
                    className="px-4 py-2 border rounded"
                  />

                  {uploadMutation.isPending && (
                    <p className="text-blue-600">Uploading...</p>
                  )}

                  {uploadMutation.error && (
                    <div className="p-4 bg-red-50 border border-red-200 rounded">
                      <pre className="whitespace-pre-wrap text-sm">{String(uploadMutation.error)}</pre>
                    </div>
                  )}

                  <div>
                    <h3 className="text-lg font-semibold mb-2">My files</h3>

                    {filesLoading && <p className="text-gray-500">Loading...</p>}

                    {filesData?.files?.length === 0 && (
                      <p className="text-gray-500">No files uploaded yet.</p>
                    )}

                    {filesData?.files?.length > 0 && (
                      <ul className="divide-y divide-gray-200 border rounded">
                        {filesData.files.map((file) => (
                          <li key={file.key} className="flex items-center justify-between px-4 py-2">
                            <span className="text-sm truncate flex-1 mr-2">{file.key}</span>
                            <div className="flex gap-2 shrink-0">
                              <button
                                onClick={() => handleDownload(file.key)}
                                className="px-3 py-1 bg-blue-500 text-white text-sm rounded hover:bg-blue-600"
                              >
                                Download
                              </button>
                              <button
                                onClick={() => deleteFileMutation.mutate(file.key)}
                                disabled={deleteFileMutation.isPending}
                                className="px-3 py-1 bg-red-500 text-white text-sm rounded hover:bg-red-600 disabled:opacity-50"
                              >
                                Delete
                              </button>
                            </div>
                          </li>
                        ))}
                      </ul>
                    )}
                  </div>
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
