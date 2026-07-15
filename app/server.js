const express = require('express');
const { Pool } = require('pg');
const redis = require('redis');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'postgres',
  user: process.env.DB_USER || 'bloguser',
  password: process.env.DB_PASSWORD || 'blogpass',
  database: process.env.DB_NAME || 'blogdb',
  port: 5432,
});

// Redis connection
const redisClient = redis.createClient({
  url: `redis://${process.env.REDIS_HOST || 'redis'}:6379`
});

redisClient.on('error', (err) => console.error('Redis Error:', err));
redisClient.connect();

// Middleware
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static('public'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/', async (req, res) => {
  try {
    // Check cache first
    const cachedPosts = await redisClient.get('posts');
    if (cachedPosts) {
      console.log('✅ Serving from Redis cache');
      return res.render('index', { 
        posts: JSON.parse(cachedPosts),
        cached: true 
      });
    }

    // Query database
    const result = await pool.query('SELECT * FROM posts ORDER BY created_at DESC');
    
    // Cache for 60 seconds
    await redisClient.set('posts', JSON.stringify(result.rows), { EX: 60 });
    
    res.render('index', { 
      posts: result.rows,
      cached: false 
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Error loading posts');
  }
});

app.post('/posts', async (req, res) => {
  const { title, content } = req.body;
  
  try {
    await pool.query(
      'INSERT INTO posts (title, content) VALUES ($1, $2)',
      [title, content]
    );
    
    // Clear cache
    await redisClient.del('posts');
    
    res.redirect('/');
  } catch (error) {
    console.error('Error creating post:', error);
    res.status(500).send('Error creating post');
  }
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    services: {
      database: pool._connected ? 'connected' : 'disconnected',
      redis: redisClient.isOpen ? 'connected' : 'disconnected'
    }
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Blog app running on port ${PORT}`);
});