-- =======================================================
-- EMPLOYEE MANAGEMENT SYSTEM DATABASE SETUP
-- Based on Problem Statement by Chris Shony (2562134)
-- =======================================================

DROP DATABASE IF EXISTS employee_management_db;
CREATE DATABASE employee_management_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE employee_management_db;

-- -------------------------------------------------------
-- MODULE 1: BEFORE JOINING (Placements & Recruitment)
-- -------------------------------------------------------

CREATE TABLE Universities (
    university_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    tier VARCHAR(50) DEFAULT 'Tier 1',
    contact_person VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    partnership_date DATE NOT NULL,
    status ENUM('Active', 'Renewal Pending', 'Inactive') DEFAULT 'Active'
);

CREATE TABLE Candidates (
    candidate_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(50),
    university_id INT,
    applied_role VARCHAR(100) NOT NULL,
    selection_stage ENUM('Applied', 'Screening', 'Technical Round', 'HR Round', 'Offered', 'Hired', 'Rejected') NOT NULL,
    interview_score DECIMAL(4, 2),
    application_date DATE NOT NULL,
    status ENUM('Hired', 'In Process', 'Rejected') NOT NULL,
    FOREIGN KEY (university_id) REFERENCES Universities(university_id) ON DELETE SET NULL
);

-- -------------------------------------------------------
-- MODULE 2: DURING EMPLOYMENT & WORKFORCE PLANNING
-- -------------------------------------------------------

CREATE TABLE Branches (
    branch_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL
);

CREATE TABLE Departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    branch_id INT,
    budget DECIMAL(12, 2) DEFAULT 0.00,
    FOREIGN KEY (branch_id) REFERENCES Branches(branch_id) ON DELETE CASCADE
);

CREATE TABLE Roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    employment_type VARCHAR(50) NOT NULL,
    payment_model VARCHAR(100) NOT NULL,
    support_requirements VARCHAR(255) NOT NULL
);

CREATE TABLE Employees (
    emp_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    department_id INT,
    role_id INT,
    hire_date DATE NOT NULL,
    status ENUM('Active', 'On Leave', 'Resigned', 'Terminated', 'Retired') NOT NULL,
    FOREIGN KEY (department_id) REFERENCES Departments(department_id) ON DELETE SET NULL,
    FOREIGN KEY (role_id) REFERENCES Roles(role_id) ON DELETE SET NULL
);

CREATE TABLE Projects (
    project_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    client_name VARCHAR(255),
    description TEXT,
    budget DECIMAL(12, 2),
    start_date DATE NOT NULL,
    end_date DATE,
    status ENUM('Planning', 'In Progress', 'Completed', 'On Hold') DEFAULT 'In Progress'
);

CREATE TABLE Employee_Projects (
    emp_id INT,
    project_id INT,
    role_in_project VARCHAR(100),
    allocation_percentage INT DEFAULT 100,
    PRIMARY KEY (emp_id, project_id),
    FOREIGN KEY (emp_id) REFERENCES Employees(emp_id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES Projects(project_id) ON DELETE CASCADE
);

CREATE TABLE Attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id INT NOT NULL,
    date DATE NOT NULL,
    status ENUM('Present', 'Absent', 'Leave', 'Half Day', 'Remote') NOT NULL,
    check_in TIME,
    check_out TIME,
    FOREIGN KEY (emp_id) REFERENCES Employees(emp_id) ON DELETE CASCADE
);

CREATE TABLE Salaries (
    salary_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id INT NOT NULL,
    base_salary DECIMAL(10, 2) NOT NULL,
    bonus DECIMAL(10, 2) DEFAULT 0.00,
    deductions DECIMAL(10, 2) DEFAULT 0.00,
    net_salary DECIMAL(10, 2) GENERATED ALWAYS AS (base_salary + bonus - deductions) STORED,
    effective_date DATE NOT NULL,
    payment_status ENUM('Paid', 'Pending', 'Processing') DEFAULT 'Paid',
    FOREIGN KEY (emp_id) REFERENCES Employees(emp_id) ON DELETE CASCADE
);

CREATE TABLE Benefits (
    benefit_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id INT NOT NULL UNIQUE,
    insurance_plan VARCHAR(255) NOT NULL,
    insurance_coverage_amount DECIMAL(10, 2) NOT NULL,
    provident_fund_number VARCHAR(100) UNIQUE,
    pf_employee_contribution DECIMAL(10, 2) DEFAULT 0.00,
    pf_employer_contribution DECIMAL(10, 2) DEFAULT 0.00,
    wellness_allowance DECIMAL(10, 2) DEFAULT 0.00,
    FOREIGN KEY (emp_id) REFERENCES Employees(emp_id) ON DELETE CASCADE
);

-- -------------------------------------------------------
-- MODULE 3: RESOURCES & ASSET TRACKING
-- -------------------------------------------------------

CREATE TABLE Resources (
    resource_id INT AUTO_INCREMENT PRIMARY KEY,
    asset_tag VARCHAR(50) UNIQUE NOT NULL,
    type ENUM('Laptop', 'Mobile', 'Charger', 'Monitor', 'Tablet', 'Vehicle') NOT NULL,
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    serial_number VARCHAR(100) UNIQUE NOT NULL,
    status ENUM('Available', 'Assigned', 'Under Maintenance', 'Retired') NOT NULL
);

CREATE TABLE Asset_Assignments (
    assignment_id INT AUTO_INCREMENT PRIMARY KEY,
    resource_id INT NOT NULL,
    emp_id INT NOT NULL,
    issue_date DATE NOT NULL,
    return_date DATE NULL,
    condition_on_issue VARCHAR(100) DEFAULT 'Good',
    condition_on_return VARCHAR(100) NULL,
    return_verified_by VARCHAR(100) NULL,
    FOREIGN KEY (resource_id) REFERENCES Resources(resource_id) ON DELETE RESTRICT,
    FOREIGN KEY (emp_id) REFERENCES Employees(emp_id) ON DELETE RESTRICT
);

-- -------------------------------------------------------
-- MODULE 4: AFTER EXIT FROM COMPANY (Exit Management)
-- -------------------------------------------------------

CREATE TABLE Exit_Records (
    exit_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id INT NOT NULL UNIQUE,
    exit_type ENUM('Resignation', 'Retirement', 'Termination') NOT NULL,
    exit_date DATE NOT NULL,
    notice_period_days INT DEFAULT 30,
    exit_interview_completed BOOLEAN DEFAULT TRUE,
    resources_cleared BOOLEAN NOT NULL DEFAULT FALSE,
    handover_notes TEXT,
    FOREIGN KEY (emp_id) REFERENCES Employees(emp_id) ON DELETE CASCADE
);

-- -------------------------------------------------------
-- MODULE 5: PENSION & RETIREMENT BENEFITS
-- -------------------------------------------------------

CREATE TABLE Pension_Eligibility (
    pension_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id INT NOT NULL UNIQUE,
    is_eligible BOOLEAN NOT NULL,
    years_of_service DECIMAL(4, 1) NOT NULL,
    last_drawn_salary DECIMAL(10, 2) NOT NULL,
    monthly_pension_amount DECIMAL(10, 2) NOT NULL,
    disbursement_status ENUM('Active', 'Pending Verification', 'Disbursed', 'Not Eligible') NOT NULL,
    pension_start_date DATE NULL,
    FOREIGN KEY (emp_id) REFERENCES Employees(emp_id) ON DELETE CASCADE
);

-- =======================================================
-- MOCK DATA INSERTION
-- =======================================================

-- 1. Universities (30 Universities)
INSERT INTO Universities (name, location, tier, contact_person, contact_email, partnership_date, status) VALUES
('Indian Institute of Technology Bombay', 'Mumbai, India', 'Tier 1', 'Prof. A. K. Sharma', 'placements@iitb.ac.in', '2018-04-10', 'Active'),
('Indian Institute of Science', 'Bangalore, India', 'Tier 1', 'Dr. Ramesh Rao', 'placements@iisc.ac.in', '2017-06-15', 'Active'),
('IIT Madras', 'Chennai, India', 'Tier 1', 'Dr. S. Ramanujan', 'tnp@iitm.ac.in', '2019-01-20', 'Active'),
('IIT Delhi', 'New Delhi, India', 'Tier 1', 'Prof. Neha Gupta', 'careers@iitd.ac.in', '2018-08-12', 'Active'),
('BITS Pilani', 'Pilani, India', 'Tier 1', 'Dr. Rajiv Menon', 'placement@pilani.bits-pilani.ac.in', '2019-03-05', 'Active'),
('National Institute of Technology Karnataka', 'Surathkal, India', 'Tier 1', 'Prof. K. Venkatesh', 'tnp@nitk.edu.in', '2020-02-14', 'Active'),
('IIT Kharagpur', 'Kharagpur, India', 'Tier 1', 'Dr. Arnab Sen', 'placement@iitkgp.ac.in', '2017-11-25', 'Active'),
('IIT Roorkee', 'Roorkee, India', 'Tier 1', 'Prof. Amitava Roy', 'placement@iitr.ac.in', '2018-10-18', 'Active'),
('Delhi Technological University', 'New Delhi, India', 'Tier 2', 'Dr. Rajeshwari Nair', 'placements@dtu.ac.in', '2020-05-19', 'Active'),
('Vellore Institute of Technology', 'Vellore, India', 'Tier 2', 'Mr. Samuel Joseph', 'pat@vit.ac.in', '2019-07-22', 'Active'),
('Stanford University', 'Stanford, CA, USA', 'Tier 1', 'Dr. Michael Chang', 'recruiting@stanford.edu', '2016-09-01', 'Active'),
('Massachusetts Institute of Technology', 'Cambridge, MA, USA', 'Tier 1', 'Dr. Laura Adams', 'careers@mit.edu', '2016-08-15', 'Active'),
('University of California, Berkeley', 'Berkeley, CA, USA', 'Tier 1', 'Prof. David Miller', 'careercenter@berkeley.edu', '2017-04-12', 'Active'),
('Carnegie Mellon University', 'Pittsburgh, PA, USA', 'Tier 1', 'Dr. Robert Chen', 'careers@cmu.edu', '2017-05-30', 'Active'),
('National University of Singapore', 'Singapore', 'Tier 1', 'Ms. Lin Mei', 'placements@nus.edu.sg', '2018-01-14', 'Active'),
('Nanyang Technological University', 'Singapore', 'Tier 1', 'Dr. Tan Wei', 'careers@ntu.edu.sg', '2018-03-25', 'Active'),
('ETH Zurich', 'Zurich, Switzerland', 'Tier 1', 'Dr. Hans Fischer', 'placements@ethz.ch', '2017-10-10', 'Active'),
('Technical University of Munich', 'Munich, Germany', 'Tier 1', 'Prof. Klaus Becker', 'careers@tum.de', '2019-06-18', 'Active'),
('Imperial College London', 'London, UK', 'Tier 1', 'Dr. Sarah Higgins', 'careers@imperial.ac.uk', '2017-12-05', 'Active'),
('University of Cambridge', 'Cambridge, UK', 'Tier 1', 'Prof. Edward Wright', 'careers@cam.ac.uk', '2016-11-12', 'Active'),
('University of Oxford', 'Oxford, UK', 'Tier 1', 'Dr. Fiona Campbell', 'careers@ox.ac.uk', '2016-10-20', 'Active'),
('University of Waterloo', 'Waterloo, ON, Canada', 'Tier 1', 'Mr. Brian Scott', 'coop@uwaterloo.ca', '2018-09-15', 'Active'),
('University of Toronto', 'Toronto, ON, Canada', 'Tier 1', 'Ms. Karen Hall', 'careers@utoronto.ca', '2018-11-01', 'Active'),
('University of Melbourne', 'Melbourne, Australia', 'Tier 1', 'Dr. James O''Connor', 'careers@unimelb.edu.au', '2019-08-10', 'Active'),
('University of New South Wales', 'Sydney, Australia', 'Tier 1', 'Ms. Chloe Taylor', 'careers@unsw.edu.au', '2020-01-15', 'Active'),
('University of Tokyo', 'Tokyo, Japan', 'Tier 1', 'Prof. Kenji Sato', 'career@u-tokyo.ac.jp', '2019-09-20', 'Renewal Pending'),
('Seoul National University', 'Seoul, South Korea', 'Tier 1', 'Dr. Min-jun Park', 'placement@snu.ac.kr', '2020-04-18', 'Active'),
('Tsinghua University', 'Beijing, China', 'Tier 1', 'Prof. Wei Zhang', 'careers@tsinghua.edu.cn', '2019-12-10', 'Renewal Pending'),
('Anna University', 'Chennai, India', 'Tier 2', 'Dr. K. Swaminathan', 'cuic@annauniv.edu', '2021-02-11', 'Active'),
('PSG College of Technology', 'Coimbatore, India', 'Tier 2', 'Dr. M. Natarajan', 'placement@psgtech.edu', '2021-03-01', 'Active');

-- 2. Candidates (30 Candidates)
INSERT INTO Candidates (name, email, phone, university_id, applied_role, selection_stage, interview_score, application_date, status) VALUES
('Aarav Sharma', 'aarav.sharma@example.com', '+91-9876543210', 1, 'Associate Software Engineer', 'Hired', 9.20, '2023-01-10', 'Hired'),
('Ananya Patel', 'ananya.patel@example.com', '+91-9876543211', 3, 'Data Analyst Intern', 'Hired', 8.80, '2023-02-15', 'Hired'),
('Rohan Verma', 'rohan.verma@example.com', '+91-9876543212', 4, 'Graduate Trainee - Fresher', 'Hired', 8.50, '2023-03-01', 'Hired'),
('Sneha Nair', 'sneha.nair@example.com', '+91-9876543213', 2, 'Research Intern', 'Hired', 9.50, '2023-01-25', 'Hired'),
('Aditya Kulkarni', 'aditya.k@example.com', '+91-9876543214', 5, 'Junior Frontend Dev', 'Offered', 8.70, '2023-04-10', 'In Process'),
('Meera Iyer', 'meera.iyer@example.com', '+91-9876543215', 6, 'Cloud Operations Trainee', 'Technical Round', 7.80, '2023-04-18', 'In Process'),
('Vikram Joshi', 'vikram.joshi@example.com', '+91-9876543216', 7, 'Backend Engineer', 'HR Round', 8.40, '2023-03-22', 'In Process'),
('Pooja Sundaram', 'pooja.s@example.com', '+91-9876543217', 8, 'QA Automation Intern', 'Screening', 7.50, '2023-05-02', 'In Process'),
('Karan Malhotra', 'karan.m@example.com', '+91-9876543218', 9, 'Graduate Trainee - Fresher', 'Rejected', 5.60, '2023-02-18', 'Rejected'),
('Divya Ranganathan', 'divya.r@example.com', '+91-9876543219', 10, 'Business Analyst', 'Applied', 7.20, '2023-05-12', 'In Process'),
('Alexander Wright', 'alex.wright@example.com', '+1-555-0101', 11, 'AI Systems Researcher', 'Hired', 9.70, '2023-01-14', 'Hired'),
('Emily Zhao', 'emily.zhao@example.com', '+1-555-0102', 12, 'Firmware Engineer', 'Hired', 9.40, '2023-01-20', 'Hired'),
('Liam Johnson', 'liam.j@example.com', '+1-555-0103', 13, 'Full Stack Dev', 'Offered', 8.90, '2023-03-15', 'In Process'),
('Sophia Taylor', 'sophia.t@example.com', '+1-555-0104', 14, 'Robotics Engineer Intern', 'Technical Round', 8.60, '2023-04-05', 'In Process'),
('Daniel Kim', 'daniel.kim@example.com', '+65-9123-4567', 15, 'Security Analyst', 'Hired', 9.10, '2023-02-10', 'Hired'),
('Rachel Tan', 'rachel.tan@example.com', '+65-9234-5678', 16, 'Product Associate Intern', 'Offered', 8.50, '2023-03-30', 'In Process'),
('Lukas Mueller', 'lukas.m@example.com', '+41-79-123-4567', 17, 'Distributed Systems Dev', 'Hired', 9.60, '2023-01-08', 'Hired'),
('Maximilian Weber', 'max.weber@example.com', '+49-170-1234567', 18, 'DevOps Trainee', 'Technical Round', 7.90, '2023-04-12', 'In Process'),
('Charlotte Davies', 'charlotte.d@example.com', '+44-7700-900123', 19, 'Data Scientist', 'HR Round', 8.80, '2023-03-25', 'In Process'),
('Oliver Smith', 'oliver.s@example.com', '+44-7700-900124', 20, 'ML Engineer', 'Hired', 9.30, '2023-01-18', 'Hired'),
('Grace Evans', 'grace.evans@example.com', '+44-7700-900125', 21, 'UX Designer Intern', 'Offered', 8.70, '2023-03-12', 'In Process'),
('Noah Tremblay', 'noah.t@example.com', '+1-416-555-0199', 22, 'Platform Engineer', 'Hired', 9.00, '2023-02-05', 'Hired'),
('Chloe Roy', 'chloe.roy@example.com', '+1-416-555-0200', 23, 'Marketing Specialist', 'Screening', 7.10, '2023-05-01', 'In Process'),
('Jack Wilson', 'jack.w@example.com', '+61-400-123-456', 24, 'Frontend Developer', 'Rejected', 6.00, '2023-02-28', 'Rejected'),
('Mia Brown', 'mia.brown@example.com', '+61-400-234-567', 25, 'People Operations Intern', 'Applied', 7.30, '2023-05-14', 'In Process'),
('Haruki Murakami', 'haruki.m@example.com', '+81-90-1234-5678', 26, 'Mobile App Developer', 'Technical Round', 8.20, '2023-04-20', 'In Process'),
('Ji-woo Park', 'jiwoo.park@example.com', '+82-10-1234-5678', 27, 'Data Engineer', 'HR Round', 8.60, '2023-03-19', 'In Process'),
('Chen Wei', 'chen.wei@example.com', '+86-138-0000-1111', 28, 'Database Admin Trainee', 'Rejected', 5.90, '2023-03-02', 'Rejected'),
('Gautam Ramesh', 'gautam.ramesh@example.com', '+91-9876543220', 29, 'QA Test Engineer', 'Hired', 8.90, '2023-02-14', 'Hired'),
('Lavanya Krishnan', 'lavanya.k@example.com', '+91-9876543221', 30, 'Embedded Systems Fresher', 'Hired', 9.10, '2023-01-29', 'Hired');

-- 3. Branches (8 global / regional hubs)
INSERT INTO Branches (name, city, country, address) VALUES
('Bengaluru Tech Park Hub', 'Bengaluru', 'India', 'Tower 4, Embassy TechVillage, Outer Ring Rd'),
('Mumbai Financial Operations', 'Mumbai', 'India', 'BKC Commercial Hub, Bandra East'),
('Hyderabad Cyber Center', 'Hyderabad', 'India', 'HITEC City, Madhapur'),
('Silicon Valley HQ', 'San Jose, CA', 'USA', '100 Innovation Way, Silicon Valley'),
('London European Office', 'London', 'UK', '25 Canary Wharf, London'),
('Singapore APAC Center', 'Singapore', 'Singapore', '1 Marina Boulevard, Central Area'),
('Toronto Engineering Lab', 'Toronto', 'Canada', '200 Bay Street, Financial District'),
('Sydney Regional Office', 'Sydney', 'Australia', '100 Barangaroo Avenue, Sydney');

-- 4. Departments (10 departments distributed across branches)
INSERT INTO Departments (name, branch_id, budget) VALUES
('Core Engineering & Platform', 1, 15000000.00),
('Cloud Infrastructure & DevOps', 1, 8000000.00),
('Data Science & AI Labs', 4, 18000000.00),
('Product Management & UX', 4, 9500000.00),
('Quality Assurance & Testing', 3, 5000000.00),
('Enterprise Sales & Marketing', 5, 12000000.00),
('Corporate Finance & Accounts', 2, 7000000.00),
('Human Resources & Talent Acquisition', 1, 4500000.00),
('Cybersecurity & Compliance', 6, 8500000.00),
('Customer Success & IT Support', 7, 6000000.00);

-- 5. Roles (Demonstrating Workforce Planning: Fresher, Employee, Freelancer, Intern, Contractor)
INSERT INTO Roles (title, employment_type, payment_model, support_requirements) VALUES
('Graduate Trainee Software Engineer', 'Fresher', 'Monthly Salary', 'Dedicated Senior Mentor, Corporate Laptop, Boot Camp Training'),
('Junior QA Engineer - Fresher', 'Fresher', 'Monthly Salary', 'Assigned Lead QA Guide, Testing Device Lab Access, Full Mentorship'),
('Associate Cloud Trainee', 'Fresher', 'Monthly Salary', 'Cloud Certifications Sponsor, Standard Laptop, Mentor'),
('Software Development Engineer II', 'Employee', 'Monthly Salary', 'MacBook Pro, Health Insurance, 401k/PF, Wellness Benefit'),
('Senior Staff Software Engineer', 'Employee', 'Monthly Salary', 'Top-tier Workstation, Dual Monitors, Comprehensive Executive Benefits'),
('Principal DevOps Architect', 'Employee', 'Monthly Salary', 'High-spec Laptop, Cloud Sandboxes, Full Benefits Suite'),
('Product Manager', 'Employee', 'Monthly Salary', 'Mobile phone, Laptop, Executive Travel & Health Allowance'),
('Lead UX/UI Designer', 'Employee', 'Monthly Salary', 'MacBook Pro, 4K Display, Tablet with Stylus, Adobe Creative Suite'),
('Senior Data Scientist', 'Employee', 'Monthly Salary', 'GPU Workstation, Python/R Cloud Clusters, Comprehensive Insurance'),
('HR Business Partner', 'Employee', 'Monthly Salary', 'Laptop, Corporate SIM, Employee Support Budget'),
('Finance Controller', 'Employee', 'Monthly Salary', 'Secure Enterprise Laptop, Financial Systems Access, Full Benefits'),
('Senior Information Security Analyst', 'Employee', 'Monthly Salary', 'Hardened Linux Laptop, Security Hardware Token, Full Insurance'),
('Freelance Mobile App Developer', 'Freelancer', 'Hourly Rate', 'Bring Own Device, Secure VPN Access, Jira/GitHub Access'),
('Freelance Technical Content Writer', 'Freelancer', 'Milestone/Contract Fee', 'Remote Workspace Token, Content Portal Access, No Equipment'),
('Freelance UI Visual Illustrator', 'Freelancer', 'Milestone/Contract Fee', 'Creative Cloud License, Secure Drive Access, Milestone Payouts'),
('Freelance Penetration Tester', 'Freelancer', 'Hourly Rate', 'Isolated Testbed Access, Non-Disclosure Token, Time-track Billing'),
('Software Engineering Intern', 'Intern', 'Stipend', 'Company Laptop, Intern Buddy, Technical Training Modules'),
('Data Science Research Intern', 'Intern', 'Stipend', 'Cloud Jupyter Hub Access, Laptop, Bi-weekly Mentorship Reviews'),
('UI/UX Design Intern', 'Intern', 'Stipend', 'Design System Sandbox, Figma Org Seat, Monitor and Laptop'),
('Cybersecurity Operations Intern', 'Intern', 'Stipend', 'SOC Access, Security Laptop, Mentor Supervision'),
('Contract Frontend Architect', 'Contractor', 'Contract Fee', 'High-spec Laptop, Direct Project SLA, Fixed Term Support'),
('Contract ERP Migration Specialist', 'Contractor', 'Contract Fee', 'Enterprise ERP Gateway, Specialized Workstation, 6-Month Term'),
('Contract Cloud Migration Consultant', 'Contractor', 'Hourly Rate', 'AWS/Azure Enterprise Access, Security Key, Remote Stipend'),
('Contract QA Automation Lead', 'Contractor', 'Contract Fee', 'Device Farm Access, Test Lead Clearance, Periodic Support'),
('Contract Database Performance Tuner', 'Contractor', 'Hourly Rate', 'DB Read-only Access, Telemetry Suite, 3-Month Extension Option'),
('Contract Security Auditor', 'Contractor', 'Milestone/Contract Fee', 'Compliance Tool Access, Audit Scope Agreement'),
('Freelance Technical Illustrator', 'Freelancer', 'Milestone/Contract Fee', 'Design System Access, Deliverable Review Gateway'),
('Junior Data Analyst - Fresher', 'Fresher', 'Monthly Salary', 'Analytics Sandbox, Python/SQL Training, Mentor Guide'),
('Full Stack Intern', 'Intern', 'Stipend', 'Development Environment, Intern Buddy, Code Review Mentorship'),
('Contract Site Reliability Engineer', 'Contractor', 'Hourly Rate', 'Production Alert Access, PagerDuty License, Remote Support');

-- 6. Employees (30 Employees with realistic lifecycles)
-- 1-20: Active/On Leave
-- 21-25: Resigned/Terminated
-- 26-30: Retired
INSERT INTO Employees (first_name, last_name, email, phone, department_id, role_id, hire_date, status) VALUES
('Aarav', 'Sharma', 'aarav.sharma@company.com', '+91-9876500001', 1, 1, '2023-06-01', 'Active'),
('Rohan', 'Verma', 'rohan.verma@company.com', '+91-9876500002', 1, 1, '2023-06-01', 'Active'),
('Priya', 'Sundaram', 'priya.sundaram@company.com', '+91-9876500003', 5, 2, '2023-07-15', 'Active'),
('Dev', 'Kapoor', 'dev.kapoor@company.com', '+91-9876500004', 2, 3, '2023-08-01', 'Active'),
('Alexander', 'Wright', 'alex.wright@company.com', '+1-408-555-0111', 3, 9, '2020-03-15', 'Active'),
('Emily', 'Zhao', 'emily.zhao@company.com', '+1-408-555-0112', 1, 4, '2021-05-10', 'Active'),
('Kavita', 'Krishnan', 'kavita.k@company.com', '+91-9876500007', 4, 8, '2019-11-01', 'Active'),
('Vikram', 'Aditya', 'vikram.aditya@company.com', '+91-9876500008', 1, 5, '2018-02-14', 'Active'),
('Neha', 'Deshmukh', 'neha.deshmukh@company.com', '+91-9876500009', 2, 6, '2017-09-01', 'Active'),
('Arjun', 'Mehta', 'arjun.mehta@company.com', '+91-9876500010', 4, 7, '2019-04-12', 'Active'),
('Sneha', 'Nair', 'sneha.nair@company.com', '+91-9876500011', 3, 18, '2024-01-10', 'Active'),
('Ananya', 'Patel', 'ananya.patel@company.com', '+91-9876500012', 3, 17, '2024-01-10', 'Active'),
('Lucas', 'Silva', 'lucas.silva@company.com', '+1-408-555-0113', 1, 13, '2023-09-01', 'Active'),
('Marcus', 'Vance', 'marcus.vance@company.com', '+44-20-7946-0114', 6, 14, '2023-11-15', 'Active'),
('Gautam', 'Ramesh', 'gautam.ramesh@company.com', '+91-9876500015', 5, 24, '2022-08-01', 'Active'),
('David', 'O''Connor', 'david.oconnor@company.com', '+61-2-9000-0116', 2, 23, '2022-03-10', 'Active'),
('Sophia', 'Chen', 'sophia.chen@company.com', '+65-6700-0117', 9, 12, '2021-01-15', 'Active'),
('Rajesh', 'Khanna', 'rajesh.khanna@company.com', '+91-9876500018', 7, 11, '2016-03-01', 'Active'),
('Maya', 'Alvarez', 'maya.alvarez@company.com', '+1-416-555-0119', 8, 10, '2018-07-20', 'On Leave'),
('Tariq', 'Mansoor', 'tariq.mansoor@company.com', '+44-20-7946-0120', 10, 4, '2020-10-05', 'Active'),
-- Resigned / Terminated
('Rahul', 'Singhania', 'rahul.s@company.com', '+91-9876500021', 1, 4, '2021-02-01', 'Resigned'),
('Jennifer', 'Lawrence', 'jennifer.l@company.com', '+1-408-555-0122', 4, 7, '2020-06-15', 'Resigned'),
('Karthik', 'Srinivasan', 'karthik.s@company.com', '+91-9876500023', 2, 6, '2019-01-10', 'Resigned'),
('Brian', 'Campbell', 'brian.c@company.com', '+44-20-7946-0124', 6, 4, '2021-09-01', 'Terminated'),
('Meenakshi', 'Sundaresan', 'meenakshi.s@company.com', '+91-9876500025', 5, 2, '2022-04-15', 'Resigned'),
-- Retired (Senior long-tenure employees)
('Dr. Harish', 'Chandra', 'harish.chandra@company.com', '+91-9876500026', 1, 5, '2005-01-10', 'Retired'),
('Suresh', 'Babu', 'suresh.babu@company.com', '+91-9876500027', 7, 11, '2007-04-15', 'Retired'),
('Katherine', 'Holloway', 'katherine.h@company.com', '+1-408-555-0128', 8, 10, '2008-09-01', 'Retired'),
('Narayanan', 'Pillai', 'narayanan.p@company.com', '+91-9876500029', 2, 6, '2006-03-20', 'Retired'),
('Alan', 'Turington', 'alan.tur@company.com', '+44-20-7946-0130', 9, 12, '2009-07-11', 'Retired');

-- 7. Projects (10 Strategic Company Projects)
INSERT INTO Projects (name, client_name, description, budget, start_date, end_date, status) VALUES
('Apollo Cloud Modernization', 'Internal Infrastructure', 'Migrating legacy on-prem services to containerized Kubernetes clusters', 1200000.00, '2023-01-15', '2024-12-31', 'In Progress'),
('FinShield Payment Gateway', 'Global Bank Corp', 'Next-gen fraud detection and real-time transaction processing pipeline', 2500000.00, '2022-06-01', '2024-06-30', 'Completed'),
('HealthPulse AI Diagnostic', 'Apex Healthcare', 'Computer vision and deep learning platform for medical imagery diagnostics', 3800000.00, '2023-03-10', '2025-03-31', 'In Progress'),
('OmniRetail Mobile Experience', 'Metro Retailers', 'Cross-platform Flutter application for retail store inventory and self-checkout', 850000.00, '2023-08-01', '2024-08-15', 'In Progress'),
('SecureVault Zero Trust SOC', 'Internal Security', 'Implementing identity-first zero trust architecture across global offices', 1500000.00, '2022-11-01', '2023-11-30', 'Completed'),
('DataMesh Enterprise Telemetry', 'Logistics Global', 'Real-time Apache Kafka streaming pipeline processing 100k events/sec', 1900000.00, '2023-05-15', '2024-10-31', 'In Progress'),
('SmartCampus University Portal', 'Higher Ed Consortium', 'Student admissions, placements, and campus analytics SaaS platform', 600000.00, '2024-01-10', '2024-12-20', 'In Progress'),
('AeroSim Digital Twin', 'SkyHigh Aerospace', 'Physics simulation digital twin for turbine lifecycle monitoring', 4200000.00, '2022-01-10', '2024-05-30', 'Completed'),
('QuantumLedger Audit Suite', 'Finance Authority', 'Immutable ledger logging for regulatory compliance and AML checks', 1750000.00, '2023-09-01', '2025-01-30', 'In Progress'),
('GreenGrid Energy Optimizer', 'Renewables Ltd', 'IoT sensor telemetry predicting solar and wind battery grid dispatch', 2100000.00, '2023-07-01', '2025-06-30', 'In Progress');

-- 8. Employee_Projects (30 Project Allocations)
INSERT INTO Employee_Projects (emp_id, project_id, role_in_project, allocation_percentage) VALUES
(1, 1, 'Junior Backend Developer', 100),
(2, 1, 'API Integration Engineer', 100),
(3, 4, 'Mobile QA Specialist', 80),
(4, 1, 'Cloud Operations Trainee', 100),
(5, 3, 'Lead AI Researcher', 90),
(5, 6, 'Data Science Consultant', 10),
(6, 1, 'Senior Backend Architect', 100),
(7, 4, 'Lead UI Designer', 75),
(7, 7, 'Design Reviewer', 25),
(8, 1, 'Technical Lead', 80),
(8, 6, 'Advisory Architect', 20),
(9, 1, 'DevOps Lead', 70),
(9, 5, 'Infrastructure Specialist', 30),
(10, 4, 'Principal Product Manager', 100),
(11, 3, 'NLP Research Intern', 100),
(12, 6, 'Data Pipeline Intern', 100),
(13, 4, 'Freelance Mobile Developer', 100),
(14, 4, 'Technical Writer', 50),
(15, 4, 'Contract QA Lead', 100),
(16, 1, 'Contract Cloud Architect', 80),
(17, 5, 'Chief Security Architect', 100),
(18, 2, 'Financial Auditor', 100),
(19, 7, 'Talent Lead', 60),
(20, 1, 'Full Stack Dev', 100),
(21, 2, 'Senior Engineer (Past)', 100),
(22, 4, 'Product Manager (Past)', 100),
(23, 1, 'Cloud Engineer (Past)', 100),
(24, 2, 'Senior Developer (Past)', 100),
(25, 4, 'QA Engineer (Past)', 100),
(26, 8, 'Founding Systems Architect', 100);

-- 9. Attendance (30 recent sample records)
INSERT INTO Attendance (emp_id, date, status, check_in, check_out) VALUES
(1, '2024-03-01', 'Present', '09:02:15', '18:05:40'),
(2, '2024-03-01', 'Present', '08:58:30', '18:10:12'),
(3, '2024-03-01', 'Remote', '09:15:00', '18:00:00'),
(4, '2024-03-01', 'Present', '09:05:10', '18:02:22'),
(5, '2024-03-01', 'Remote', '08:45:00', '17:45:00'),
(6, '2024-03-01', 'Present', '09:10:45', '18:30:10'),
(7, '2024-03-01', 'Present', '09:30:00', '18:35:00'),
(8, '2024-03-01', 'Present', '08:50:12', '18:40:50'),
(9, '2024-03-01', 'Remote', '09:00:00', '18:00:00'),
(10, '2024-03-01', 'Present', '09:12:30', '18:15:00'),
(11, '2024-03-01', 'Present', '09:00:00', '17:30:00'),
(12, '2024-03-01', 'Present', '09:05:00', '17:35:00'),
(13, '2024-03-01', 'Remote', '10:00:00', '19:00:00'),
(14, '2024-03-01', 'Remote', '10:15:00', '16:30:00'),
(15, '2024-03-01', 'Present', '09:20:00', '18:10:00'),
(16, '2024-03-01', 'Remote', '08:30:00', '17:30:00'),
(17, '2024-03-01', 'Present', '09:00:00', '18:30:00'),
(18, '2024-03-01', 'Present', '08:45:00', '17:45:00'),
(19, '2024-03-01', 'Leave', NULL, NULL),
(20, '2024-03-01', 'Present', '09:14:00', '18:05:00'),
(1, '2024-03-02', 'Present', '09:00:00', '18:00:00'),
(2, '2024-03-02', 'Half Day', '09:00:00', '13:30:00'),
(3, '2024-03-02', 'Present', '09:10:00', '18:05:00'),
(4, '2024-03-02', 'Present', '08:55:00', '18:00:00'),
(5, '2024-03-02', 'Remote', '09:00:00', '18:00:00'),
(6, '2024-03-02', 'Absent', NULL, NULL),
(7, '2024-03-02', 'Present', '09:20:00', '18:15:00'),
(8, '2024-03-02', 'Present', '08:50:00', '18:30:00'),
(9, '2024-03-02', 'Present', '09:05:00', '18:10:00'),
(10, '2024-03-02', 'Remote', '09:00:00', '18:00:00');

-- 10. Salaries (30 salary records reflecting roles, experience and payments)
INSERT INTO Salaries (emp_id, base_salary, bonus, deductions, effective_date, payment_status) VALUES
(1, 45000.00, 3000.00, 2000.00, '2024-02-28', 'Paid'),
(2, 45000.00, 2500.00, 2000.00, '2024-02-28', 'Paid'),
(3, 42000.00, 2000.00, 1800.00, '2024-02-28', 'Paid'),
(4, 40000.00, 2000.00, 1800.00, '2024-02-28', 'Paid'),
(5, 145000.00, 15000.00, 12000.00, '2024-02-28', 'Paid'),
(6, 95000.00, 10000.00, 7500.00, '2024-02-28', 'Paid'),
(7, 85000.00, 8000.00, 6500.00, '2024-02-28', 'Paid'),
(8, 160000.00, 20000.00, 15000.00, '2024-02-28', 'Paid'),
(9, 135000.00, 14000.00, 11000.00, '2024-02-28', 'Paid'),
(10, 110000.00, 12000.00, 9000.00, '2024-02-28', 'Paid'),
(11, 25000.00, 1500.00, 500.00, '2024-02-28', 'Paid'),
(12, 25000.00, 1500.00, 500.00, '2024-02-28', 'Paid'),
(13, 65000.00, 0.00, 3000.00, '2024-02-28', 'Paid'),
(14, 50000.00, 0.00, 2000.00, '2024-02-28', 'Paid'),
(15, 80000.00, 5000.00, 4000.00, '2024-02-28', 'Paid'),
(16, 95000.00, 0.00, 5000.00, '2024-02-28', 'Paid'),
(17, 140000.00, 15000.00, 11500.00, '2024-02-28', 'Paid'),
(18, 125000.00, 12000.00, 10000.00, '2024-02-28', 'Paid'),
(19, 75000.00, 6000.00, 5500.00, '2024-02-28', 'Paid'),
(20, 90000.00, 8500.00, 7000.00, '2024-02-28', 'Paid'),
(21, 92000.00, 0.00, 7000.00, '2023-11-30', 'Paid'),
(22, 105000.00, 0.00, 8500.00, '2023-10-31', 'Paid'),
(23, 130000.00, 0.00, 10500.00, '2023-12-31', 'Paid'),
(24, 88000.00, 0.00, 6500.00, '2023-08-31', 'Paid'),
(25, 42000.00, 0.00, 3000.00, '2023-09-30', 'Paid'),
(26, 185000.00, 25000.00, 15000.00, '2023-06-30', 'Paid'),
(27, 150000.00, 18000.00, 12000.00, '2023-05-31', 'Paid'),
(28, 115000.00, 12000.00, 9500.00, '2023-09-30', 'Paid'),
(29, 165000.00, 20000.00, 14000.00, '2023-04-30', 'Paid'),
(30, 155000.00, 18000.00, 13000.00, '2023-08-31', 'Paid');

-- 11. Benefits (30 records with Insurance, PF, and support contributions)
INSERT INTO Benefits (emp_id, insurance_plan, insurance_coverage_amount, provident_fund_number, pf_employee_contribution, pf_employer_contribution, wellness_allowance) VALUES
(1, 'Standard Health Plan', 500000.00, 'PF-2023-001', 3600.00, 3600.00, 1500.00),
(2, 'Standard Health Plan', 500000.00, 'PF-2023-002', 3600.00, 3600.00, 1500.00),
(3, 'Standard Health Plan', 500000.00, 'PF-2023-003', 3360.00, 3360.00, 1200.00),
(4, 'Standard Health Plan', 500000.00, 'PF-2023-004', 3200.00, 3200.00, 1200.00),
(5, 'Executive Platinum Family Plan', 2000000.00, 'PF-2020-005', 11600.00, 11600.00, 4000.00),
(6, 'Comprehensive Gold Plan', 1000000.00, 'PF-2021-006', 7600.00, 7600.00, 2500.00),
(7, 'Comprehensive Gold Plan', 1000000.00, 'PF-2019-007', 6800.00, 6800.00, 2500.00),
(8, 'Executive Platinum Family Plan', 2500000.00, 'PF-2018-008', 12800.00, 12800.00, 5000.00),
(9, 'Executive Platinum Family Plan', 2000000.00, 'PF-2017-009', 10800.00, 10800.00, 4500.00),
(10, 'Comprehensive Gold Plan', 1000000.00, 'PF-2019-010', 8800.00, 8800.00, 3000.00),
(11, 'Intern Accidental & Medical Cover', 250000.00, 'PF-2024-011', 1200.00, 1200.00, 500.00),
(12, 'Intern Accidental & Medical Cover', 250000.00, 'PF-2024-012', 1200.00, 1200.00, 500.00),
(13, 'Contractor Supplemental Health', 300000.00, NULL, 0.00, 0.00, 0.00),
(14, 'Contractor Supplemental Health', 300000.00, NULL, 0.00, 0.00, 0.00),
(15, 'Contractor Supplemental Health', 500000.00, NULL, 0.00, 0.00, 0.00),
(16, 'Contractor Supplemental Health', 500000.00, NULL, 0.00, 0.00, 0.00),
(17, 'Executive Platinum Family Plan', 2000000.00, 'PF-2021-017', 11200.00, 11200.00, 4000.00),
(18, 'Comprehensive Gold Plan', 1000000.00, 'PF-2016-018', 10000.00, 10000.00, 3500.00),
(19, 'Comprehensive Gold Plan', 1000000.00, 'PF-2018-019', 6000.00, 6000.00, 2500.00),
(20, 'Comprehensive Gold Plan', 1000000.00, 'PF-2020-020', 7200.00, 7200.00, 2500.00),
(21, 'Comprehensive Gold Plan (Archived)', 1000000.00, 'PF-2021-021', 7360.00, 7360.00, 0.00),
(22, 'Comprehensive Gold Plan (Archived)', 1000000.00, 'PF-2020-022', 8400.00, 8400.00, 0.00),
(23, 'Executive Platinum Plan (Archived)', 2000000.00, 'PF-2019-023', 10400.00, 10400.00, 0.00),
(24, 'Comprehensive Gold Plan (Archived)', 1000000.00, 'PF-2021-024', 7040.00, 7040.00, 0.00),
(25, 'Standard Health Plan (Archived)', 500000.00, 'PF-2022-025', 3360.00, 3360.00, 0.00),
(26, 'Senior Pensioner Medical Cover', 3000000.00, 'PF-2005-026', 14800.00, 14800.00, 5000.00),
(27, 'Senior Pensioner Medical Cover', 2500000.00, 'PF-2007-027', 12000.00, 12000.00, 4500.00),
(28, 'Senior Pensioner Medical Cover', 2000000.00, 'PF-2008-028', 9200.00, 9200.00, 4000.00),
(29, 'Senior Pensioner Medical Cover', 3000000.00, 'PF-2006-029', 13200.00, 13200.00, 5000.00),
(30, 'Senior Pensioner Medical Cover', 2500000.00, 'PF-2009-030', 12400.00, 12400.00, 4500.00);

-- 12. Resources (30 assets: Laptops, Mobiles, Chargers, Monitors, etc.)
INSERT INTO Resources (asset_tag, type, brand, model, serial_number, status) VALUES
('AST-LAP-001', 'Laptop', 'Apple', 'MacBook Pro 16 M3 Max', 'SN-APL-9001', 'Assigned'),
('AST-LAP-002', 'Laptop', 'Apple', 'MacBook Pro 14 M2 Pro', 'SN-APL-9002', 'Assigned'),
('AST-LAP-003', 'Laptop', 'Dell', 'XPS 15 9530 i9', 'SN-DEL-9003', 'Assigned'),
('AST-LAP-004', 'Laptop', 'Lenovo', 'ThinkPad T14s Gen 4', 'SN-LEN-9004', 'Assigned'),
('AST-LAP-005', 'Laptop', 'Apple', 'MacBook Air 15 M2', 'SN-APL-9005', 'Assigned'),
('AST-LAP-006', 'Laptop', 'Dell', 'Latitude 7440', 'SN-DEL-9006', 'Assigned'),
('AST-LAP-007', 'Laptop', 'HP', 'EliteBook 840 G10', 'SN-HP-9007', 'Assigned'),
('AST-LAP-008', 'Laptop', 'Apple', 'MacBook Pro 16 M2', 'SN-APL-9008', 'Assigned'),
('AST-LAP-009', 'Laptop', 'Dell', 'Precision 5680 Workstation', 'SN-DEL-9009', 'Assigned'),
('AST-LAP-010', 'Laptop', 'Lenovo', 'ThinkPad P1 Gen 6', 'SN-LEN-9010', 'Assigned'),
('AST-MOB-011', 'Mobile', 'Apple', 'iPhone 15 Pro Max', 'SN-IPH-9011', 'Assigned'),
('AST-MOB-012', 'Mobile', 'Samsung', 'Galaxy S24 Ultra', 'SN-SAM-9012', 'Assigned'),
('AST-MOB-013', 'Mobile', 'Google', 'Pixel 8 Pro', 'SN-PIX-9013', 'Assigned'),
('AST-MOB-014', 'Mobile', 'Apple', 'iPhone 14', 'SN-IPH-9014', 'Available'),
('AST-MOB-015', 'Mobile', 'Samsung', 'Galaxy A54 Enterprise', 'SN-SAM-9015', 'Available'),
('AST-CHG-016', 'Charger', 'Apple', '140W USB-C Power Adapter', 'SN-CHG-9016', 'Assigned'),
('AST-CHG-017', 'Charger', 'Dell', '130W Type-C GaN Charger', 'SN-CHG-9017', 'Assigned'),
('AST-CHG-018', 'Charger', 'Anker', 'Prime 100W 3-Port GaN', 'SN-ANK-9018', 'Assigned'),
('AST-CHG-019', 'Charger', 'Lenovo', '65W USB-C Slim Charger', 'SN-CHG-9019', 'Available'),
('AST-CHG-020', 'Charger', 'Samsung', '45W Super Fast Charger', 'SN-CHG-9020', 'Available'),
('AST-MON-021', 'Monitor', 'Dell', 'UltraSharp 32 4K U3223QE', 'SN-DEL-9021', 'Assigned'),
('AST-MON-022', 'Monitor', 'LG', '34WK95U 5K2K UltraWide', 'SN-LG-9022', 'Assigned'),
('AST-MON-023', 'Monitor', 'Apple', 'Studio Display 27 5K', 'SN-APL-9023', 'Assigned'),
('AST-TAB-024', 'Tablet', 'Apple', 'iPad Pro 12.9 M2', 'SN-TAB-9024', 'Assigned'),
('AST-TAB-025', 'Tablet', 'Samsung', 'Galaxy Tab S9+', 'SN-TAB-9025', 'Available'),
('AST-LAP-026', 'Laptop', 'Dell', 'Latitude 5530', 'SN-DEL-9026', 'Available'),
('AST-LAP-027', 'Laptop', 'Lenovo', 'ThinkPad X1 Carbon Gen 10', 'SN-LEN-9027', 'Available'),
('AST-LAP-028', 'Laptop', 'HP', 'ZBook Studio G9', 'SN-HP-9028', 'Under Maintenance'),
('AST-MOB-029', 'Mobile', 'Apple', 'iPhone 13', 'SN-IPH-9029', 'Retired'),
('AST-CHG-030', 'Charger', 'Generic', 'Universal 65W Multi-Pin', 'SN-GEN-9030', 'Retired');

-- 13. Asset_Assignments (Assignment & Return tracking with lifecycle alignment)
-- Active employees currently holding equipment:
-- Exited employees who returned equipment: return_date populated, condition noted
-- Exited employee with pending equipment: emp_id 24 still holds AST-LAP-007
INSERT INTO Asset_Assignments (resource_id, emp_id, issue_date, return_date, condition_on_issue, condition_on_return, return_verified_by) VALUES
(1, 8, '2023-01-15', NULL, 'Brand New Sealed', NULL, NULL),
(2, 6, '2023-02-10', NULL, 'Excellent', NULL, NULL),
(3, 1, '2023-06-05', NULL, 'New', NULL, NULL),
(4, 2, '2023-06-05', NULL, 'New', NULL, NULL),
(5, 7, '2023-03-20', NULL, 'Excellent', NULL, NULL),
(6, 4, '2023-08-05', NULL, 'Good Refurbished', NULL, NULL),
(8, 5, '2023-01-10', NULL, 'Brand New', NULL, NULL),
(9, 9, '2023-02-01', NULL, 'Brand New', NULL, NULL),
(10, 17, '2023-04-12', NULL, 'Brand New', NULL, NULL),
(11, 10, '2023-05-18', NULL, 'Brand New', NULL, NULL),
(12, 8, '2023-01-20', NULL, 'Brand New', NULL, NULL),
(13, 17, '2023-04-15', NULL, 'Brand New', NULL, NULL),
(16, 8, '2023-01-15', NULL, 'Original Apple 140W', NULL, NULL),
(17, 1, '2023-06-05', NULL, 'Dell Original GaN', NULL, NULL),
(18, 5, '2023-01-10', NULL, 'Anker GaN 100W', NULL, NULL),
(21, 5, '2023-02-15', NULL, 'Factory Calibrated', NULL, NULL),
(22, 6, '2023-03-01', NULL, 'Factory Calibrated', NULL, NULL),
(23, 7, '2023-03-25', NULL, 'Factory Calibrated', NULL, NULL),
(24, 7, '2023-04-01', NULL, 'Brand New with Apple Pencil', NULL, NULL),
-- Exited employees who completed return process:
(26, 21, '2021-02-05', '2023-11-28', 'Good', 'Returned in Good Condition, No Damage', 'IT Asset Admin'),
(19, 21, '2021-02-05', '2023-11-28', 'Good', 'Working Adapter Returned', 'IT Asset Admin'),
(27, 22, '2020-06-20', '2023-10-25', 'Good', 'Returned with normal wear', 'IT Asset Admin'),
(14, 22, '2020-06-20', '2023-10-25', 'Good', 'Phone factory reset and returned', 'IT Asset Admin'),
(20, 23, '2019-01-15', '2023-12-28', 'Good', 'Original fast charger returned', 'IT Asset Admin'),
(15, 25, '2022-04-20', '2023-09-28', 'Good', 'Returned intact', 'IT Asset Admin'),
-- Retirees who completed full handover:
(28, 26, '2020-01-10', '2023-06-25', 'Good', 'Sent for cleaning and maintenance', 'IT Asset Admin'),
(29, 27, '2019-05-12', '2023-05-20', 'Good', 'Retired phone decommissioned', 'IT Asset Admin'),
(30, 29, '2018-04-10', '2023-04-22', 'Fair', 'End of life decommissioned', 'IT Asset Admin'),
(25, 10, '2023-05-20', '2023-12-15', 'Good', 'Temporary tablet returned after design sprint', 'IT Asset Admin'),
-- Employee 24 (Terminated): Did NOT clear equipment (Pending return)
(7, 24, '2021-09-05', NULL, 'Good', NULL, NULL);

-- 14. Exit_Records (Records for exited employees 21 to 30)
INSERT INTO Exit_Records (emp_id, exit_type, exit_date, notice_period_days, exit_interview_completed, resources_cleared, handover_notes) VALUES
(21, 'Resignation', '2023-11-30', 60, TRUE, TRUE, 'Resigned for higher studies abroad. All project modules handed over to Dev Kapoor.'),
(22, 'Resignation', '2023-10-31', 30, TRUE, TRUE, 'Relocating to Europe. Product documentation and roadmap transferred to Arjun Mehta.'),
(23, 'Resignation', '2023-12-31', 45, TRUE, TRUE, 'Joined early stage startup. Cloud credentials revoked and handed over to Neha Deshmukh.'),
(24, 'Termination', '2023-08-31', 0, FALSE, FALSE, 'Contract terminated for compliance violation. Laptop AST-LAP-007 recovery in legal notice stage.'),
(25, 'Resignation', '2023-09-30', 30, TRUE, TRUE, 'Career transition to product design. Testing suites archived and handed over.'),
(26, 'Retirement', '2023-06-30', 90, TRUE, TRUE, 'Superannuation after 18.5 years of exemplary service. Full emeritus clearance completed.'),
(27, 'Retirement', '2023-05-31', 90, TRUE, TRUE, 'Superannuation after 16.1 years in Finance Control. Accounts audit signed off.'),
(28, 'Retirement', '2023-09-30', 90, TRUE, TRUE, 'Superannuation after 15.1 years in Human Resources. Succession plan completed.'),
(29, 'Retirement', '2023-04-30', 90, TRUE, TRUE, 'Superannuation after 17.1 years in Cloud Infrastructure. Architecture handover complete.'),
(30, 'Retirement', '2023-08-31', 90, TRUE, TRUE, 'Superannuation after 14.1 years in Security. Cryptographic key rotation completed.');

-- 15. Pension_Eligibility (Retirement Support & Pension Entitlement Verification)
INSERT INTO Pension_Eligibility (emp_id, is_eligible, years_of_service, last_drawn_salary, monthly_pension_amount, disbursement_status, pension_start_date) VALUES
-- Retired Employees (Tenure >= 10 years, superannuated, pension verified and active)
(26, TRUE, 18.5, 185000.00, 92500.00, 'Active', '2023-07-01'),
(27, TRUE, 16.1, 150000.00, 75000.00, 'Active', '2023-06-01'),
(28, TRUE, 15.1, 115000.00, 57500.00, 'Active', '2023-10-01'),
(29, TRUE, 17.1, 165000.00, 82500.00, 'Active', '2023-05-01'),
(30, TRUE, 14.1, 155000.00, 77500.00, 'Active', '2023-09-01'),
-- Resigned / Terminated (Not eligible for superannuation pension)
(21, FALSE, 2.8, 92000.00, 0.00, 'Not Eligible', NULL),
(22, FALSE, 3.4, 105000.00, 0.00, 'Not Eligible', NULL),
(23, FALSE, 4.9, 130000.00, 0.00, 'Not Eligible', NULL),
(24, FALSE, 1.9, 88000.00, 0.00, 'Not Eligible', NULL),
(25, FALSE, 1.4, 42000.00, 0.00, 'Not Eligible', NULL),
-- Senior Active Employees (Projected eligibility tracking)
(8, TRUE, 6.1, 160000.00, 80000.00, 'Pending Verification', NULL),
(9, TRUE, 6.5, 135000.00, 67500.00, 'Pending Verification', NULL),
(18, TRUE, 8.0, 125000.00, 62500.00, 'Pending Verification', NULL),
(7, FALSE, 4.3, 85000.00, 0.00, 'Not Eligible', NULL),
(10, FALSE, 4.9, 110000.00, 0.00, 'Not Eligible', NULL),
(6, FALSE, 2.8, 95000.00, 0.00, 'Not Eligible', NULL),
(5, FALSE, 3.9, 145000.00, 0.00, 'Not Eligible', NULL),
(19, FALSE, 5.6, 75000.00, 0.00, 'Not Eligible', NULL),
(20, FALSE, 3.4, 90000.00, 0.00, 'Not Eligible', NULL),
(17, FALSE, 3.1, 140000.00, 0.00, 'Not Eligible', NULL),
(1, FALSE, 0.8, 45000.00, 0.00, 'Not Eligible', NULL),
(2, FALSE, 0.8, 45000.00, 0.00, 'Not Eligible', NULL),
(3, FALSE, 0.6, 42000.00, 0.00, 'Not Eligible', NULL),
(4, FALSE, 0.6, 40000.00, 0.00, 'Not Eligible', NULL),
(11, FALSE, 0.2, 25000.00, 0.00, 'Not Eligible', NULL),
(12, FALSE, 0.2, 25000.00, 0.00, 'Not Eligible', NULL),
(13, FALSE, 0.5, 65000.00, 0.00, 'Not Eligible', NULL),
(14, FALSE, 0.3, 50000.00, 0.00, 'Not Eligible', NULL),
(15, FALSE, 1.6, 80000.00, 0.00, 'Not Eligible', NULL),
(16, FALSE, 2.0, 95000.00, 0.00, 'Not Eligible', NULL);
