const express = require('express');
const { Pool } = require('pg');
const redis = require('redis');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: 5432,
});

// Redis connection
const redisClient = redis.createClient({
  url: `redis://${process.env.REDIS_HOST || 'redis'}:6379`
});

redisClient.on('error', (err) => console.error('Redis Error:', err));

// Middleware
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'public')));
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

  if (!title || !content) {
    return res.status(400).send('Title and content are required');
  }
  
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

app.get('/health', async (req, res) => {
  const services = {
    database: 'disconnected',
    redis: redisClient.isOpen ? 'connected' : 'disconnected'
  };

  try {
    await pool.query('SELECT 1');
    services.database = 'connected';
  } catch (error) {
    console.error('Health check database error:', error);
  }

  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    services
  });
});

const startServer = async () => {
  try {
    await redisClient.connect();
    console.log('✅ Connected to Redis');
  } catch (error) {
    console.error('Failed to connect to Redis:', error);
  }

  app.listen(PORT, () => {
    console.log(`🚀 Blog app running on port ${PORT}`);
  });
};

startServer();