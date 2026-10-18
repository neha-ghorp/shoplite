const fs = require('fs');
const express = require('express');
const { Pool } = require('pg');
const client = require('prom-client');

const app = express();
const PORT = process.env.PORT || 3001;

// Prometheus metrics (RED: rate, errors, duration) + Node.js process metrics
client.collectDefaultMetrics();
const httpDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
});
app.use((req, res, next) => {
  const end = httpDuration.startTimer();
  // route pattern (/users/:id), not the raw URL, so label values stay few (low cardinality)
  res.on('finish', () => end({ method: req.method, route: req.route?.path || 'unmatched', status: res.statusCode }));
  next();
});
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

// Fallback data when no database is configured (local dev, existing Helm chart)
const users = [
  { id: 1, name: 'Alice' },
  { id: 2, name: 'Bob' },
  { id: 3, name: 'Charlie' },
];

// Postgres is used only when DB_HOST is set. The password is read from a file
// (Swarm secret / Kubernetes Secret mounted at /run/secrets), never from an env var.
const pool = process.env.DB_HOST
  ? new Pool({
      host: process.env.DB_HOST,
      database: process.env.DB_NAME || 'shoplite',
      user: process.env.DB_USER || 'shoplite',
      password: fs.readFileSync(process.env.DB_PASSWORD_FILE || '/run/secrets/db_password', 'utf8').trim(),
      connectionTimeoutMillis: 3000, // fail fast instead of hanging when the DB is down
      query_timeout: 5000,
    })
  : null;

// Idle pooled connections die when the DB restarts. Without this handler Node treats it as an
// unhandled 'error' event and the whole process crashes; found in the DB-outage drill.
pool?.on('error', (err) => console.error('idle DB connection lost:', err.message));

async function findUsers() {
  if (!pool) return users;
  const { rows } = await pool.query('SELECT id, name FROM users ORDER BY id');
  return rows;
}

// Liveness: the process is up. Never checks dependencies, or a DB outage restarts every pod.
app.get('/health', (req, res) => res.json({ status: 'ok' }));

// Readiness: can we actually serve requests right now?
app.get('/ready', async (req, res) => {
  try {
    if (pool) await pool.query('SELECT 1');
    res.json({ status: 'ready' });
  } catch (err) {
    res.status(503).json({ status: 'not ready', error: err.message });
  }
});

app.get('/users', async (req, res) => {
  try {
    res.json(await findUsers());
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/users/:id', async (req, res) => {
  try {
    const user = (await findUsers()).find((u) => u.id === Number(req.params.id));
    if (!user) return res.status(404).json({ error: 'user not found' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => console.log(`users-service listening on ${PORT} (db: ${process.env.DB_HOST || 'in-memory'})`));
