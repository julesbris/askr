-- Training Management System Database Schema
-- Cook Shire Council

-- ============================================
-- 1. DEPARTMENTS
-- ============================================
CREATE TABLE departments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================
-- 2. ROLES
-- ============================================
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    department_id INT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL,
    INDEX idx_department (department_id)
);

-- ============================================
-- 3. COMPETENCY CATEGORIES
-- ============================================
CREATE TABLE competency_categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 4. COMPETENCIES
-- ============================================
CREATE TABLE competencies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category_id INT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES competency_categories(id) ON DELETE SET NULL,
    INDEX idx_category (category_id)
);

-- ============================================
-- 5. ROLE COMPETENCY REQUIREMENTS
-- ============================================
CREATE TABLE role_competencies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role_id INT NOT NULL,
    competency_id INT NOT NULL,
    requirement_type ENUM('M(A)', 'M(S)', 'D(A)', 'D(S)') NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (competency_id) REFERENCES competencies(id) ON DELETE CASCADE,
    UNIQUE KEY unique_role_competency (role_id, competency_id),
    INDEX idx_role (role_id),
    INDEX idx_competency (competency_id)
);

-- ============================================
-- 6. TRAINING COURSES
-- ============================================
CREATE TABLE training_courses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    provider_type ENUM('internal', 'external') NOT NULL,
    provider_name VARCHAR(150) NOT NULL,
    recertification_months INT NULL COMMENT 'NULL means no expiry',
    internal_verification_allowed BOOLEAN DEFAULT FALSE,
    internal_verifier_role VARCHAR(100),
    cost DECIMAL(10, 2) DEFAULT 0.00,
    duration VARCHAR(50) COMMENT 'e.g., 2 days, 4 hours',
    description TEXT,
    notes TEXT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_provider_type (provider_type),
    INDEX idx_active (active)
);

-- ============================================
-- 7. COURSE COMPETENCY MAPPING
-- Link courses to competencies they fulfill
-- ============================================
CREATE TABLE course_competencies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    course_id INT NOT NULL,
    competency_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES training_courses(id) ON DELETE CASCADE,
    FOREIGN KEY (competency_id) REFERENCES competencies(id) ON DELETE CASCADE,
    UNIQUE KEY unique_course_competency (course_id, competency_id)
);

-- ============================================
-- 8. PEOPLE/STAFF
-- ============================================
CREATE TABLE people (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    role_id INT,
    department_id INT,
    employee_number VARCHAR(50) UNIQUE,
    start_date DATE,
    end_date DATE,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE SET NULL,
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL,
    INDEX idx_role (role_id),
    INDEX idx_department (department_id),
    INDEX idx_active (active),
    INDEX idx_name (last_name, first_name)
);

-- ============================================
-- 9. TRAINING RECORDS
-- ============================================
CREATE TABLE training_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    person_id INT NOT NULL,
    competency_id INT NOT NULL,
    course_id INT,
    completed_date DATE NOT NULL,
    expiry_date DATE,
    certificate_number VARCHAR(100),
    provider_name VARCHAR(150),
    cost DECIMAL(10, 2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT COMMENT 'User who created this record',
    FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE CASCADE,
    FOREIGN KEY (competency_id) REFERENCES competencies(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES training_courses(id) ON DELETE SET NULL,
    INDEX idx_person (person_id),
    INDEX idx_competency (competency_id),
    INDEX idx_expiry (expiry_date),
    INDEX idx_completed (completed_date)
);

-- ============================================
-- 10. INTERNAL VERIFICATIONS
-- ============================================
CREATE TABLE internal_verifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    training_record_id INT NOT NULL,
    verified_by_person_id INT NOT NULL COMMENT 'Staff member who verified',
    verification_date DATE NOT NULL,
    verification_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (training_record_id) REFERENCES training_records(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by_person_id) REFERENCES people(id) ON DELETE CASCADE,
    INDEX idx_training_record (training_record_id),
    INDEX idx_verified_by (verified_by_person_id)
);

-- ============================================
-- 11. TRAINING REMINDERS/NOTIFICATIONS
-- ============================================
CREATE TABLE training_reminders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    person_id INT NOT NULL,
    training_record_id INT,
    reminder_type ENUM('expiring_soon', 'expired', 'not_completed') NOT NULL,
    reminder_date DATE NOT NULL,
    sent BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE CASCADE,
    FOREIGN KEY (training_record_id) REFERENCES training_records(id) ON DELETE CASCADE,
    INDEX idx_person (person_id),
    INDEX idx_reminder_date (reminder_date),
    INDEX idx_sent (sent)
);

-- ============================================
-- 12. AUDIT LOG
-- ============================================
CREATE TABLE audit_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    old_values JSON,
    new_values JSON,
    changed_by INT COMMENT 'User who made the change',
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    INDEX idx_table_record (table_name, record_id),
    INDEX idx_changed_at (changed_at)
);

-- ============================================
-- 13. USERS (for system access)
-- ============================================
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    person_id INT UNIQUE COMMENT 'Link to people table',
    role ENUM('admin', 'manager', 'supervisor', 'viewer') DEFAULT 'viewer',
    active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE CASCADE,
    INDEX idx_active (active)
);

-- ============================================
-- SAMPLE DATA INSERTS
-- ============================================

-- Insert Departments
INSERT INTO departments (name, description) VALUES
('Fleet & Civil Works', 'Fleet management and civil construction'),
('Engineering', 'Engineering and project management'),
('Water & Waste', 'Water and wastewater services'),
('Financial Services', 'Finance, payroll, and accounting'),
('Information & Communications Technology', 'IT services and support'),
('Communications & Engagement', 'Media and community engagement'),
('People and Performance', 'HR and WHS'),
('Building & Facilities', 'Building maintenance and facilities'),
('Planning & Environment', 'Planning, compliance, and environmental health'),
('Community Lifestyle', 'Libraries, pools, and community services'),
('Regional Development', 'Tourism, events, and economic development'),
('Office of the CEO', 'Governance and executive support');

-- Insert some sample roles
INSERT INTO roles (name, department_id) VALUES
('Depot Administration Officer', 1),
('Diesel Fitter', 1),
('Civil Construction Ganger', 1),
('Workshop Foreman', 2),
('Manager Fleet & Workshop', 2),
('Plumbers (Water & Wastewater)', 3),
('Water & Wastewater Treatment Plant Operator', 3),
('Manager Water & Waste', 3),
('Payroll Officer', 4),
('Accountant', 4),
('Finance Manager', 4),
('ICT Operations & Support Officer', 5),
('ICT System Administrator', 5),
('WHS Manager', 7),
('Safety & Training Advisor', 7);

-- Insert competency categories
INSERT INTO competency_categories (name) VALUES
('Vehicle Licences'),
('Safety & Induction'),
('Technical Skills'),
('Leadership & Management'),
('Administration');

-- Insert sample competencies
INSERT INTO competencies (name, category_id) VALUES
('White Card - Construction Induction', 2),
('Car Licence (C)', 1),
('Medium Rigid (MR)', 1),
('Heavy Rigid (HR)', 1),
('First Aid Certificate', 2),
('Working with Children Check (Blue Card)', 2),
('Manual Handling', 2),
('Forklift Operation', 3),
('Confined Space Entry', 2),
('Electrical Safety', 2);

-- Insert sample courses
INSERT INTO training_courses (name, provider_type, provider_name, recertification_months, internal_verification_allowed, internal_verifier_role, cost, duration, description) VALUES
('White Card - Construction Induction', 'external', 'SafeWork QLD', NULL, FALSE, NULL, 120.00, '1 day', 'Required for all construction workers'),
('First Aid Certificate', 'external', 'St Johns Ambulance', 36, FALSE, NULL, 180.00, '2 days', 'CPR and First Aid training'),
('Forklift Operation', 'internal', 'Cook Shire Council', 60, TRUE, 'Workshop Foreman', 0.00, '3 days', 'Internal forklift training and certification'),
('Manual Handling', 'internal', 'Cook Shire Council', 24, TRUE, 'WHS Manager', 0.00, '4 hours', 'Manual handling refresher training'),
('Confined Space Entry', 'external', 'WorkSafe QLD', 24, FALSE, NULL, 250.00, '1 day', 'Required for confined space work'),
('Driver Training - MR Licence', 'external', 'QLD Transport', NULL, FALSE, NULL, 350.00, '2 days', 'Medium Rigid licence training');

-- Link courses to competencies
INSERT INTO course_competencies (course_id, competency_id) VALUES
(1, 1), -- White Card -> White Card competency
(2, 5), -- First Aid Course -> First Aid competency
(3, 8), -- Forklift Course -> Forklift competency
(4, 7), -- Manual Handling Course -> Manual Handling competency
(5, 9), -- Confined Space -> Confined Space competency
(6, 3); -- MR Training -> MR Licence competency

-- Insert sample people
INSERT INTO people (first_name, last_name, email, role_id, department_id, employee_number, start_date, active) VALUES
('John', 'Smith', 'john.smith@cookshire.qld.gov.au', 2, 1, 'EMP001', '2020-03-15', TRUE),
('Sarah', 'Johnson', 'sarah.johnson@cookshire.qld.gov.au', 3, 1, 'EMP002', '2019-07-01', TRUE),
('Michael', 'Brown', 'michael.brown@cookshire.qld.gov.au', 4, 2, 'EMP003', '2018-11-20', TRUE),
('Emily', 'Davis', 'emily.davis@cookshire.qld.gov.au', 6, 3, 'EMP004', '2021-02-10', TRUE),
('David', 'Wilson', 'david.wilson@cookshire.qld.gov.au', 9, 4, 'EMP005', '2017-05-05', TRUE);

-- Insert role competency requirements
INSERT INTO role_competencies (role_id, competency_id, requirement_type, notes) VALUES
-- Diesel Fitter requirements
(2, 1, 'M(A)', 'Required for all construction roles'),
(2, 2, 'M(A)', 'Required for driving'),
(2, 3, 'D(A)', 'Desirable for larger vehicles'),
(2, 7, 'M(A)', 'Safety requirement'),

-- Civil Construction Ganger
(3, 1, 'M(A)', 'Required for all construction roles'),
(3, 2, 'M(A)', 'Required for driving'),
(3, 3, 'M(A)', 'Required for operating equipment'),
(3, 7, 'M(A)', 'Safety requirement'),
(3, 5, 'M(S)', 'Required for this role'),

-- Workshop Foreman
(4, 1, 'M(A)', 'Required for all construction roles'),
(4, 2, 'M(A)', 'Required for driving'),
(4, 7, 'M(A)', 'Safety requirement'),
(4, 8, 'M(S)', 'Required to verify forklift training');

-- Insert sample training records
INSERT INTO training_records (person_id, competency_id, course_id, completed_date, expiry_date, certificate_number, provider_name, cost) VALUES
(1, 1, 1, '2023-01-15', NULL, 'WC2023-001', 'SafeWork QLD', 120.00),
(1, 5, 2, '2024-06-10', '2027-06-10', 'FA2024-456', 'St Johns Ambulance', 180.00),
(1, 7, 4, '2024-09-01', '2026-09-01', 'INT-MH-2024-001', 'Cook Shire Council', 0.00),
(2, 1, 1, '2022-11-20', NULL, 'WC2022-089', 'SafeWork QLD', 120.00),
(2, 5, 2, '2023-03-15', '2026-03-15', 'FA2023-123', 'St Johns Ambulance', 180.00),
(3, 1, 1, '2023-05-10', NULL, 'WC2023-045', 'SafeWork QLD', 120.00),
(3, 8, 3, '2023-08-20', '2028-08-20', 'INT-FL-2023-012', 'Cook Shire Council', 0.00);

-- Insert sample internal verifications
INSERT INTO internal_verifications (training_record_id, verified_by_person_id, verification_date, verification_notes) VALUES
(3, 3, '2024-09-05', 'Practical assessment completed successfully'),
(7, 3, '2023-08-25', 'Forklift operation assessment passed');

-- ============================================
-- USEFUL VIEWS
-- ============================================

-- View: Training Compliance by Person
CREATE VIEW view_person_training_compliance AS
SELECT 
    p.id AS person_id,
    CONCAT(p.first_name, ' ', p.last_name) AS person_name,
    p.email,
    r.name AS role_name,
    d.name AS department_name,
    COUNT(DISTINCT rc.competency_id) AS required_competencies,
    COUNT(DISTINCT tr.competency_id) AS completed_competencies,
    ROUND(COUNT(DISTINCT tr.competency_id) * 100.0 / NULLIF(COUNT(DISTINCT rc.competency_id), 0), 2) AS completion_percentage
FROM people p
LEFT JOIN roles r ON p.role_id = r.id
LEFT JOIN departments d ON p.department_id = d.id
LEFT JOIN role_competencies rc ON r.id = rc.role_id
LEFT JOIN training_records tr ON p.id = tr.person_id AND rc.competency_id = tr.competency_id
WHERE p.active = TRUE
GROUP BY p.id, p.first_name, p.last_name, p.email, r.name, d.name;

-- View: Expiring Training (within 30 days)
CREATE VIEW view_expiring_training AS
SELECT 
    p.id AS person_id,
    CONCAT(p.first_name, ' ', p.last_name) AS person_name,
    p.email,
    c.name AS competency_name,
    tc.name AS course_name,
    tr.completed_date,
    tr.expiry_date,
    DATEDIFF(tr.expiry_date, CURDATE()) AS days_until_expiry
FROM training_records tr
JOIN people p ON tr.person_id = p.id
JOIN competencies c ON tr.competency_id = c.id
LEFT JOIN training_courses tc ON tr.course_id = tc.id
WHERE tr.expiry_date IS NOT NULL
  AND tr.expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
  AND p.active = TRUE
ORDER BY tr.expiry_date;

-- View: Expired Training
CREATE VIEW view_expired_training AS
SELECT 
    p.id AS person_id,
    CONCAT(p.first_name, ' ', p.last_name) AS person_name,
    p.email,
    c.name AS competency_name,
    tc.name AS course_name,
    tr.completed_date,
    tr.expiry_date,
    ABS(DATEDIFF(tr.expiry_date, CURDATE())) AS days_overdue
FROM training_records tr
JOIN people p ON tr.person_id = p.id
JOIN competencies c ON tr.competency_id = c.id
LEFT JOIN training_courses tc ON tr.course_id = tc.id
WHERE tr.expiry_date IS NOT NULL
  AND tr.expiry_date < CURDATE()
  AND p.active = TRUE
ORDER BY tr.expiry_date;

-- View: Training by Department Summary
CREATE VIEW view_department_training_summary AS
SELECT 
    d.name AS department_name,
    COUNT(DISTINCT p.id) AS total_people,
    SUM(CASE WHEN tr.id IS NOT NULL THEN 1 ELSE 0 END) AS total_trainings,
    SUM(CASE WHEN tr.expiry_date IS NULL OR tr.expiry_date >= CURDATE() THEN 1 ELSE 0 END) AS current_trainings,
    SUM(CASE WHEN tr.expiry_date < CURDATE() THEN 1 ELSE 0 END) AS expired_trainings
FROM departments d
LEFT JOIN people p ON d.id = p.department_id AND p.active = TRUE
LEFT JOIN training_records tr ON p.id = tr.person_id
GROUP BY d.name
ORDER BY d.name;

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Additional composite indexes for common queries
CREATE INDEX idx_training_person_competency ON training_records(person_id, competency_id);
CREATE INDEX idx_training_expiry_active ON training_records(expiry_date) WHERE expiry_date IS NOT NULL;
CREATE INDEX idx_people_active_role ON people(active, role_id);

-- ============================================
-- STORED PROCEDURES (Optional - for automation)
-- ============================================

DELIMITER //

-- Procedure to calculate expiry date based on course
CREATE PROCEDURE sp_calculate_expiry_date(
    IN p_completed_date DATE,
    IN p_course_id INT,
    OUT p_expiry_date DATE
)
BEGIN
    DECLARE v_recert_months INT;
    
    SELECT recertification_months INTO v_recert_months
    FROM training_courses
    WHERE id = p_course_id;
    
    IF v_recert_months IS NOT NULL THEN
        SET p_expiry_date = DATE_ADD(p_completed_date, INTERVAL v_recert_months MONTH);
    ELSE
        SET p_expiry_date = NULL;
    END IF;
END //

-- Procedure to get person's training status
CREATE PROCEDURE sp_get_person_training_status(
    IN p_person_id INT
)
BEGIN
    SELECT 
        c.id AS competency_id,
        c.name AS competency_name,
        c.category_id,
        rc.requirement_type,
        tr.id AS training_record_id,
        tr.completed_date,
        tr.expiry_date,
        CASE 
            WHEN tr.id IS NULL THEN 'pending'
            WHEN tr.expiry_date IS NULL THEN 'complete'
            WHEN tr.expiry_date < CURDATE() THEN 'expired'
            WHEN tr.expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY) THEN 'expiring'
            ELSE 'complete'
        END AS status
    FROM people p
    JOIN roles r ON p.role_id = r.id
    JOIN role_competencies rc ON r.id = rc.role_id
    JOIN competencies c ON rc.competency_id = c.id
    LEFT JOIN training_records tr ON p.id = tr.person_id AND c.id = tr.competency_id
    WHERE p.id = p_person_id
    ORDER BY rc.requirement_type, c.name;
END //

DELIMITER ;

-- ============================================
-- GRANTS (adjust as needed for your setup)
-- ============================================
-- CREATE USER 'training_app'@'%' IDENTIFIED BY 'secure_password_here';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON training_db.* TO 'training_app'@'%';
-- FLUSH PRIVILEGES;
