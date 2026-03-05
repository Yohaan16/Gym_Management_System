const mysql = require('mysql2/promise');
const config = require('./config');

class Database {
  constructor() {
    this.pool = null;
    this.isConnected = false;
  }

  async initialize() {
    try {
      this.pool = mysql.createPool(config.DATABASE);
      await this.testConnection();
      console.log('✓ Database connected successfully');
      this.isConnected = true;
      return true;
    } catch (error) {
      console.error('✗ Database connection failed:', error.message);
      this.isConnected = false;
      return false;
    }
  }

  async testConnection() {
    const connection = await this.pool.getConnection();
    connection.release();
  }

  async getConnection() {
    if (!this.pool) {
      throw new Error('Database not initialized');
    }
    return await this.pool.getConnection();
  }

  async query(sql, params = []) {
    const connection = await this.getConnection();
    try {
      const result = await connection.execute(sql, params);
      if (sql.trim().toUpperCase().startsWith('SELECT')) {
        return result[0];
      } else {
        return result[0];
      }
    } catch (error) {
      console.error('Database query error:', error);
      throw error;
    } finally {
      connection.release();
    }
  }

  async close() {
    if (this.pool) {
      await this.pool.end();
      this.isConnected = false;
    }
  }
}

module.exports = new Database();