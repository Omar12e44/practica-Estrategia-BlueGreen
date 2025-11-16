const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.VERSION || '1.0.0';
const COLOR = process.env.COLOR || 'blue';

app.use(express.json());

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    version: VERSION,
    color: COLOR,
    timestamp: new Date().toISOString()
  });
});

app.get('/', (req, res) => {
  res.json({
    message: 'API Blue-Green Deployment',
    version: VERSION,
    environment: COLOR,
    endpoints: {
      health: '/health',
      info: '/api/info',
      users: '/api/users',
      products: '/api/products'
    }
  });
});

app.get('/api/info', (req, res) => {
  res.json({
    appName: 'Blue-Green API',
    version: VERSION,
    color: COLOR,
    description: 'API de demostración para despliegue Blue-Green',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

app.get('/api/users', (req, res) => {
  const users = [
    { id: 1, name: 'Juan Pérez', email: 'juan@example.com', environment: COLOR },
    { id: 2, name: 'María García', email: 'maria@example.com', environment: COLOR },
    { id: 3, name: 'Carlos López', email: 'carlos@example.com', environment: COLOR }
  ];
  res.json({
    version: VERSION,
    color: COLOR,
    data: users,
    count: users.length
  });
});

app.get('/api/products', (req, res) => {
  const products = [
    { id: 1, name: 'Laptop', price: 999.99, stock: 15, environment: COLOR },
    { id: 2, name: 'Mouse', price: 29.99, stock: 50, environment: COLOR },
    { id: 3, name: 'Teclado', price: 79.99, stock: 30, environment: COLOR },
    { id: 4, name: 'Monitor', price: 299.99, stock: 20, environment: COLOR }
  ];
  res.json({
    version: VERSION,
    color: COLOR,
    data: products,
    count: products.length
  });
});

app.get('/api/load', (req, res) => {
  const start = Date.now();
  let count = 0;
  while (Date.now() - start < 100) {
    count++;
  }
  res.json({
    message: 'Load test completed',
    version: VERSION,
    color: COLOR,
    iterations: count,
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});