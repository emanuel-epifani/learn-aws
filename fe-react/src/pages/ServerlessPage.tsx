import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { uploadFile, listFiles, downloadFile, deleteFile } from '../services/apiService'

export default function ServerlessPage() {
  const queryClient = useQueryClient()

  const { data: filesData, isLoading: filesLoading } = useQuery({
    queryKey: ['files'],
    queryFn: listFiles
  })

  const uploadMutation = useMutation({
    mutationFn: (file: File) => uploadFile(file),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['files'] })
  })

  const deleteFileMutation = useMutation({
    mutationFn: (key: string) => deleteFile(key),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['files'] })
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

  return (
    <div className="p-6">
      <h2 className="text-2xl font-bold mb-4">File Bin (Serverless)</h2>
      <p className="text-sm text-gray-500 mb-4">API Gateway + Lambda + S3</p>

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

          {(filesData?.files?.length ?? 0) > 0 && (
            <ul className="divide-y divide-gray-200 border rounded">
              {filesData!.files!.map((file) => (
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
  )
}
