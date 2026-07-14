-- Create posts table
CREATE TABLE IF NOT EXISTS posts (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO posts (title, content) VALUES 
  ('Welcome to Docker Blog!', 'This is your first post. Docker is amazing!'),
  ('Multi-Container Apps', 'Using Docker Compose makes orchestration easy.'),
  ('Caching with Redis', 'Redis helps make your app super fast!');

-- Create user for application
CREATE USER bloguser WITH PASSWORD 'blogpass';
GRANT ALL PRIVILEGES ON DATABASE blogdb TO bloguser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO bloguser;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO bloguser;