#!/usr/bin/env node
// Idempotent helper to create the `attendance` table using the app's DB config.
// Usage: node scripts/ensure-attendance-table.js

const db = require('../config/database');

const DDL = `
CREATE TABLE IF NOT EXISTS attendance (
  attendance_id INT AUTO_INCREMENT PRIMARY KEY,
  member_id INT NOT NULL,
  jti VARCHAR(64) DEFAULT NULL,
  status ENUM('IN','OUT') NOT NULL,
  scanned_by INT DEFAULT NULL,
  scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (member_id) REFERENCES member(member_id) ON DELETE CASCADE,
  UNIQUE KEY uniq_attendance_jti (jti)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
`;

async function main() {
  try {
    await db.initialize();
    if (!db.isConnected) throw new Error('Database not connected');

    console.log('Ensuring attendance table exists...');
    await db.query(DDL);
    console.log('✅ attendance table ensured (CREATE TABLE IF NOT EXISTS executed)');
  } catch (err) {
    console.error('Failed to ensure attendance table:', err.message || err);
    process.exitCode = 1;
  } finally {
    await db.close();
  }
}

if (require.main === module) main();
