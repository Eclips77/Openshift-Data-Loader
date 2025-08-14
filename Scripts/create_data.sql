IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='data' AND xtype='U')
CREATE TABLE data (
  ID INT PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL
);

INSERT INTO data (ID, first_name, last_name) VALUES
(1, 'Ada', 'Lovelace'),
(2, 'Alan', 'Turing'),
(3, 'Grace', 'Hopper'),
(4, 'Edsger', 'Dijkstra'),
(5, 'Donald', 'Knuth');