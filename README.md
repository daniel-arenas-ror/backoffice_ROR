
docker-compose -f docker-compose.yml up -d

## start redis

 brew services start redis

## start sidekiq

 bundle exec sidekiq
