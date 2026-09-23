const express = require('express');

const app = express();
const PORT = process.env.PORT || 3002;
const USERS_URL = process.env.USERS_URL || 'http://localhost:3001';

const orders = [
  { id: 101, userId: 1, item: 'Laptop', amount: 1200 },
  { id: 102, userId: 2, item: 'Phone', amount: 800 },
  { id: 103, userId: 1, item: 'Headphones', amount: 150 },
];

app.get('/health', (req, res) => res.json({ status: 'ok' }));

// Enrich each order with the user's name from users-service
app.get('/orders', async (req, res) => {
  try {
    const resp = await fetch(`${USERS_URL}/users`);
    const users = await resp.json();
    const result = orders.map((o) => ({
      ...o,
      userName: users.find((u) => u.id === o.userId)?.name || 'unknown',
    }));
    res.json(result);
  } catch (err) {
    console.error('failed to reach users-service:', err.message);
    res.status(502).json({ error: 'users-service unavailable' });
  }
});

app.listen(PORT, () => console.log(`orders-service listening on ${PORT} (users: ${USERS_URL})`));
