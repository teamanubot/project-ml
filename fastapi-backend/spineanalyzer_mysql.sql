-- MySQL schema for SpineAnalyzer (converted from SQLite)
CREATE TABLE IF NOT EXISTS users (
  id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS analyses (
  id INT NOT NULL AUTO_INCREMENT,
  user_id INT NOT NULL,
  image_path VARCHAR(255) NULL,
  angle DOUBLE NULL,
  analysis_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  notes TEXT NULL,
  PRIMARY KEY (id),
  KEY idx_analyses_user_id (user_id),
  CONSTRAINT fk_analyses_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE NO ACTION ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO users (id, name, email, password, created_at) VALUES
(1, 'admin', 'admin@admin.com', '$2y$12$P15w7a1DW7fFlMt0oPKhp.6zlRAUKL35oWfYhYkmtlYBEYzWWCSl6', '2025-12-15 00:45:01'),
(2, 'rivai', 'rivaimunthe02@gmail.com', '$2y$12$P15w7a1DW7fFlMt0oPKhp.6zlRAUKL35oWfYhYkmtlYBEYzWWCSl6', '2025-12-15 00:45:36');