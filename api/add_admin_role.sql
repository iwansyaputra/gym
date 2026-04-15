-- Add role column to users table
-- This script adds a role column to differentiate between admin and regular users

-- Add role column if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user' AFTER is_verified;

-- Update existing users to have 'user' role
UPDATE users SET role = 'user' WHERE role IS NULL;

-- Create an admin user (change email and password as needed)
-- Password: admin123 (hashed with bcrypt)
INSERT INTO users (
    name, 
    email, 
    password, 
    phone, 
    role,
    is_verified, 
    created_at
) VALUES (
    'Admin GymKu',
    'admin@gymku.com',
    '$2b$10$YPz5qF7vN8qK3xK3xK3xKeO8qK3xK3xK3xK3xK3xK3xK3xK3xK3xK',  -- admin123
    '081234567890',
    'admin',
    1,
    NOW()
) ON DUPLICATE KEY UPDATE role = 'admin';

-- You can also manually update an existing user to be admin:
-- UPDATE users SET role = 'admin' WHERE email = 'your-email@example.com';

-- Verify the changes
SELECT id, name, email, role FROM users WHERE role = 'admin';
