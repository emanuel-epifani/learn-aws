import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { listNotes, createNote, deleteNote } from '../services/apiService'

export default function ContainerPage() {
  const queryClient = useQueryClient()
  const [noteTitle, setNoteTitle] = useState('')
  const [noteContent, setNoteContent] = useState('')

  const { data: notesData, isLoading: notesLoading } = useQuery({
    queryKey: ['notes'],
    queryFn: listNotes
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

  const handleSaveNote = () => {
    if (noteTitle && noteContent) {
      createNoteMutation.mutate({ title: noteTitle, content: noteContent })
    }
  }

  return (
    <div className="p-6">
      <h2 className="text-2xl font-bold mb-4">Note Manager (Container)</h2>
      <p className="text-sm text-gray-500 mb-4">ALB + ECS Fargate + RDS PostgreSQL</p>

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

          {(notesData?.notes?.length ?? 0) > 0 && (
            <ul className="divide-y divide-gray-200 border rounded">
              {notesData!.notes!.map((note) => (
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
  )
}
