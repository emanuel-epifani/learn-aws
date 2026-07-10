const express = require("express");
const { Pool } = require("pg");
const { CognitoJwtVerifier } = require("aws-jwt-verify");

const app = express();
app.use(express.json());

const port = process.env.PORT || 3000;

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: false,
});

const verifier = CognitoJwtVerifier.create({
  userPoolId: process.env.COGNITO_USER_POOL_ID,
  tokenUse: "id",
  clientId: process.env.COGNITO_CLIENT_ID,
});

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Missing Authorization header" });
  }

  const token = authHeader.split(" ")[1];
  verifier
    .verify(token)
    .then((payload) => {
      req.user = payload;
      next();
    })
    .catch((err) => {
      return res.status(401).json({ error: "Invalid token" });
    });
}

app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" });
});

app.get("/api/notes", authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, title, content, created_at FROM notes ORDER BY created_at DESC"
    );
    res.json({ notes: result.rows });
  } catch (err) {
    console.error("Error fetching notes:", err);
    res.status(500).json({ error: "Failed to fetch notes" });
  }
});

app.post("/api/notes", authMiddleware, async (req, res) => {
  const { title, content } = req.body;

  if (!title || !content) {
    return res.status(400).json({ error: "title and content are required" });
  }

  try {
    const result = await pool.query(
      "INSERT INTO notes (title, content) VALUES ($1, $2) RETURNING id, title, content, created_at",
      [title, content]
    );
    res.status(201).json({ note: result.rows[0] });
  } catch (err) {
    console.error("Error creating note:", err);
    res.status(500).json({ error: "Failed to create note" });
  }
});

app.delete("/api/notes/:id", authMiddleware, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query("DELETE FROM notes WHERE id = $1 RETURNING id", [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Note not found" });
    }

    res.json({ deleted: true, id });
  } catch (err) {
    console.error("Error deleting note:", err);
    res.status(500).json({ error: "Failed to delete note" });
  }
});

async function initDB() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS notes (
      id SERIAL PRIMARY KEY,
      title VARCHAR(255) NOT NULL,
      content TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT NOW()
    )
  `);
  console.log("Database initialized");
}

async function start() {
  try {
    await initDB();
    app.listen(port, () => {
      console.log(`Server running on port ${port}`);
    });
  } catch (err) {
    console.error("Failed to start server:", err);
    process.exit(1);
  }
}

start();
