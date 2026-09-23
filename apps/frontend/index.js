const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;
const USERS_URL = process.env.USERS_URL || 'http://localhost:3001';
const ORDERS_URL = process.env.ORDERS_URL || 'http://localhost:3002';

app.get('/health', (req, res) => res.json({ status: 'ok' }));

// Server-side proxy so the browser never needs to reach internal k8s services
const proxy = (target) => async (req, res) => {
  try {
    const resp = await fetch(target);
    res.status(resp.status).json(await resp.json());
  } catch (err) {
    res.status(502).json({ error: `cannot reach ${target}` });
  }
};
app.get('/api/users', proxy(`${USERS_URL}/users`));
app.get('/api/orders', proxy(`${ORDERS_URL}/orders`));

app.get('/', (req, res) => {
  res.send(`<!DOCTYPE html>
<html>
<head><title>ShopLite</title></head>
<body style="font-family: sans-serif; max-width: 700px; margin: 40px auto;">
  <h1>ShopLite</h1>
  <h2>Users</h2><pre id="users">loading...</pre>
  <h2>Orders</h2><pre id="orders">loading...</pre>
  <script>
    const load = (url, id) => fetch(url).then(r => r.json())
      .then(d => document.getElementById(id).textContent = JSON.stringify(d, null, 2))
      .catch(e => document.getElementById(id).textContent = 'error: ' + e);
    load('/api/users', 'users');
    load('/api/orders', 'orders');
  </script>
</body>
</html>`);
});

app.listen(PORT, () => console.log(`frontend listening on ${PORT}`));
