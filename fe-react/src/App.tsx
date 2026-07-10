import { useMutation } from '@tanstack/react-query'
import { Authenticator, ThemeProvider } from '@aws-amplify/ui-react'
import { Amplify } from 'aws-amplify'
import '@aws-amplify/ui-react/styles.css'
import awsConfig from './config/aws-exports'
import { uploadFile } from './services/apiService'
import './App.css'

Amplify.configure(awsConfig)

function App() {
  const uploadMutation = useMutation({
    mutationFn: (file: File) => uploadFile(file)
  })

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      uploadMutation.mutate(file)
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

            <main>
              <div className="p-6">
                <h2 className="text-2xl font-bold mb-4">File Upload</h2>

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

                  {uploadMutation.data && (
                    <div className="p-4 bg-green-50 border border-green-200 rounded">
                      <h3 className="text-lg font-semibold mb-2">Upload successful!</h3>
                      <pre className="whitespace-pre-wrap text-sm">{JSON.stringify(uploadMutation.data, null, 2)}</pre>
                    </div>
                  )}

                  {uploadMutation.error && (
                    <div className="p-4 bg-red-50 border border-red-200 rounded">
                      <h3 className="text-lg font-semibold mb-2">Upload Error:</h3>
                      <pre className="whitespace-pre-wrap text-sm">{String(uploadMutation.error)}</pre>
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
