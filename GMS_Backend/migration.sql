-- -- Migration script to update booking_time column from TIME to VARCHAR
-- -- Run this if you have existing data in the booking table

-- -- Add payment_intent_id column to payment table
-- ALTER TABLE payment ADD COLUMN payment_intent_id VARCHAR(255) NULL AFTER payment_id;

-- -- Add payment_intent_id column to booking table
-- ALTER TABLE booking ADD COLUMN payment_intent_id VARCHAR(255) NULL AFTER booking_time;

-- -- Update booking status to include 'Waiting'
-- ALTER TABLE booking MODIFY COLUMN status ENUM('Confirmed', 'Cancelled', 'Pending', 'Waiting') DEFAULT 'Pending';

-- ALTER TABLE booking MODIFY COLUMN booking_time VARCHAR(20) NOT NULL;

-- -- Add status column to registration_application table
-- ALTER TABLE registration_application ADD COLUMN status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending';

-- -- Update member table to include additional fields
-- ALTER TABLE member ADD COLUMN gender ENUM('Male','Female') DEFAULT 'Male';
-- ALTER TABLE member ADD COLUMN dateOfBirth DATE;
-- ALTER TABLE member ADD COLUMN address VARCHAR(255);
-- ALTER TABLE member ADD COLUMN password VARCHAR(255);

-- Create membership table
CREATE TABLE IF NOT EXISTS membership (
    membership_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    membership_type VARCHAR(50) NOT NULL,
    status ENUM('active','expired','cancelled') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES member(member_id) ON DELETE CASCADE
);

-- Create notice table if it doesn't exist
CREATE TABLE IF NOT EXISTS notice (
    notice_id INT AUTO_INCREMENT PRIMARY KEY,
    staff_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    posted_date DATE NOT NULL,
    target_type ENUM('ALL', 'SELECTED') DEFAULT 'ALL',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE
);

-- Add target_type column if it doesn't exist
ALTER TABLE notice ADD COLUMN IF NOT EXISTS target_type ENUM('ALL', 'SELECTED') DEFAULT 'ALL';
ALTER TABLE notice ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Create notice_recipient table for targeted notices
CREATE TABLE IF NOT EXISTS notice_recipient (
    notice_recipient_id INT AUTO_INCREMENT PRIMARY KEY,
    notice_id INT NOT NULL,
    member_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (notice_id) REFERENCES notice(notice_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES member(member_id) ON DELETE CASCADE,
    UNIQUE KEY unique_notice_member (notice_id, member_id)
);

-- Insert sample data for testing
-- INSERT INTO member (name, email, phone, gender, dateOfBirth, address, password) VALUES
-- ('John Smith', 'john@example.com', '123-456-7890', 'Male', '1990-05-15', '123 Main St, City, State', '$2b$10$hashedpassword1'),
-- ('Emma Wilson', 'emma@example.com', '123-456-7891', 'Female', '1985-08-22', '456 Oak Ave, City, State', '$2b$10$hashedpassword2'),
-- ('David Jones', 'david@example.com', '123-456-7892', 'Male', '1992-12-10', '789 Pine Rd, City, State', '$2b$10$hashedpassword3'),
-- ('Sophia Brown', 'sophia@example.com', '123-456-7893', 'Female', '1988-03-30', '321 Elm St, City, State', '$2b$10$hashedpassword4');

-- INSERT INTO membership (member_id, start_date, end_date, membership_type, status) VALUES
-- (1, '2026-01-01', '2026-12-31', 'Premium', 'active'),
-- (2, '2026-01-01', '2026-06-30', 'Standard', 'active'),
-- (3, '2025-12-01', '2026-01-15', 'Basic', 'active'),
-- (4, '2025-06-01', '2025-12-31', 'Premium', 'expired');

-- Create cancel_class table for cancelled class slots
CREATE TABLE IF NOT EXISTS cancel_class (
    cancel_id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT NOT NULL,
    cancel_date DATE NOT NULL,
    cancel_timeslot VARCHAR(20) NOT NULL,
    cancelled_by INT NOT NULL,
    cancelled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES class(class_id) ON DELETE CASCADE,
    FOREIGN KEY (cancelled_by) REFERENCES staff(staff_id) ON DELETE CASCADE,
    UNIQUE KEY unique_cancel_slot (class_id, cancel_date, cancel_timeslot)
);

-- Create attendance table to record check-ins (IN) and check-outs (OUT)
CREATE TABLE IF NOT EXISTS attendance (
  attendance_id INT AUTO_INCREMENT PRIMARY KEY,
  member_id INT NOT NULL,
  jti VARCHAR(64) DEFAULT NULL,
  status ENUM('IN','OUT') NOT NULL,
  scanned_by INT DEFAULT NULL,
  scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (member_id) REFERENCES member(member_id) ON DELETE CASCADE,
  UNIQUE KEY uniq_attendance_jti (jti)
);
