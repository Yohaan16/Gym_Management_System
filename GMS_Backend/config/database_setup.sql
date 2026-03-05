-- Database setup for GMS Backend
-- Run this script to create the necessary tables

-- Create member table
CREATE TABLE IF NOT EXISTS member (
  member_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20),
  gender ENUM('Male', 'Female', 'Other') DEFAULT 'Other',
  date_of_birth DATE,
  address TEXT,
  password VARCHAR(255) NOT NULL,
  status ENUM('Active', 'Inactive', 'Pending') DEFAULT 'Pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create weight table
CREATE TABLE IF NOT EXISTS weight (
  weight_id INT AUTO_INCREMENT PRIMARY KEY,
  member_id INT NOT NULL,
  weight DECIMAL(5,2) NOT NULL,
  record_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (member_id) REFERENCES member(member_id) ON DELETE CASCADE,
  UNIQUE KEY unique_member_date (member_id, record_date)
);

-- Create goal table
CREATE TABLE IF NOT EXISTS goal (
  goal_id INT AUTO_INCREMENT PRIMARY KEY,
  member_id INT NOT NULL,
  goal_type VARCHAR(50) NOT NULL,
  target_value DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (member_id) REFERENCES member(member_id) ON DELETE CASCADE,
  UNIQUE KEY unique_member_goal_type (member_id, goal_type)
);

-- Create daily_tracking table
CREATE TABLE IF NOT EXISTS daily_tracking (
  tracking_id INT AUTO_INCREMENT PRIMARY KEY,
  member_id INT NOT NULL,
  calories_intake DECIMAL(8,2) DEFAULT 0,
  calories_burnt DECIMAL(8,2) DEFAULT 0,
  steps INT DEFAULT 0,
  water_consumed DECIMAL(5,2) DEFAULT 0,
  record_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (member_id) REFERENCES member(member_id) ON DELETE CASCADE,
  UNIQUE KEY unique_member_date_tracking (member_id, record_date)
);

-- Create booking table
CREATE TABLE IF NOT EXISTS booking (
  booking_id INT AUTO_INCREMENT PRIMARY KEY,
  member_id INT NOT NULL,
  class_id INT,
  booking_date DATE NOT NULL,
  booking_time VARCHAR(20) NOT NULL,
  status ENUM('Confirmed', 'Cancelled', 'Pending') DEFAULT 'Pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (member_id) REFERENCES member(member_id) ON DELETE CASCADE
);

-- Create payment table
CREATE TABLE IF NOT EXISTS payment (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  member_id INT NULL,
  application_id INT NULL,
  payment_source VARCHAR(50) DEFAULT 'registration',
  amount DECIMAL(10,2) NOT NULL,
  payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  payment_method VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (member_id) REFERENCES member(member_id) ON DELETE CASCADE
);

-- Create registration_application table
CREATE TABLE IF NOT EXISTS registration_application (
  application_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20),
  gender ENUM('Male', 'Female', 'Other') DEFAULT 'Other',
  dateOfBirth DATE,
  address TEXT,
  password VARCHAR(255) NOT NULL,
  application_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  payment ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
  status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
  registration_date TIMESTAMP NULL,
  member_id INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (member_id) REFERENCES member(member_id) ON DELETE SET NULL
);