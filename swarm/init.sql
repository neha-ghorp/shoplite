-- Runs once, on the first start of an empty database volume
CREATE TABLE users (
  id   INT PRIMARY KEY,
  name TEXT NOT NULL
);

INSERT INTO users (id, name) VALUES
  (1, 'Alice'),
  (2, 'Bob'),
  (3, 'Charlie');
