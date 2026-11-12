import { getPool } from './db.js';

async function verifyAll() {
    const pool = getPool();
    console.log('Testing all CLI queries...');

    // 1. Employee query
    const [q1] = await pool.query(`
        SELECT 
            e.emp_id AS ID,
            CONCAT(e.first_name, ' ', e.last_name) AS Name,
            e.email AS Email,
            COALESCE(d.name, 'Unassigned') AS Department,
            COALESCE(b.city, 'N/A') AS Branch,
            COALESCE(r.title, 'N/A') AS Role,
            COALESCE(r.employment_type, 'N/A') AS Type,
            e.status AS Status
        FROM Employees e
        LEFT JOIN Departments d ON e.department_id = d.department_id
        LEFT JOIN Branches b ON d.branch_id = b.branch_id
        LEFT JOIN Roles r ON e.role_id = r.role_id
        LIMIT 5;
    `);
    console.log('✔ Query 1 (Employees):', q1.length, 'rows');

    // 2. Candidate query
    const [q2] = await pool.query(`
        SELECT c.candidate_id, c.name, u.name as univ, c.selection_stage, c.interview_score
        FROM Candidates c
        LEFT JOIN Universities u ON c.university_id = u.university_id
        LIMIT 5;
    `);
    console.log('✔ Query 2 (Candidates):', q2.length, 'rows');

    // 3. Workforce distribution query
    const [q3] = await pool.query(`
        SELECT 
            r.employment_type AS WorkforceType,
            COUNT(e.emp_id) AS TotalEmployees,
            ROUND(AVG(s.base_salary), 2) AS AvgBasePay,
            ROUND(SUM(s.base_salary), 2) AS TotalPayrollExpense
        FROM Roles r
        JOIN Employees e ON r.role_id = e.role_id
        LEFT JOIN Salaries s ON e.emp_id = s.emp_id
        GROUP BY r.employment_type;
    `);
    console.log('✔ Query 3 (Workforce Distribution):', q3.length, 'categories');

    // 4. Asset assignments query
    const [q4] = await pool.query(`
        SELECT a.assignment_id, r.asset_tag, r.type, e.emp_id, a.issue_date
        FROM Asset_Assignments a
        JOIN Resources r ON a.resource_id = r.resource_id
        JOIN Employees e ON a.emp_id = e.emp_id
        WHERE a.return_date IS NULL
        LIMIT 5;
    `);
    console.log('✔ Query 4 (Active Assets):', q4.length, 'rows');

    // 5. Exit clearance query
    const [q5] = await pool.query(`
        SELECT 
            e.emp_id AS EmpID,
            CONCAT(e.first_name, ' ', e.last_name) AS Employee,
            x.exit_type,
            r.asset_tag,
            CONCAT(r.brand, ' ', r.model) AS Device
        FROM Employees e
        JOIN Exit_Records x ON e.emp_id = x.emp_id
        JOIN Asset_Assignments a ON e.emp_id = a.emp_id AND a.return_date IS NULL
        JOIN Resources r ON a.resource_id = r.resource_id;
    `);
    console.log('✔ Query 5 (Unreturned Assets by Exited Personnel):', q5.length, 'flagged records');

    // 6. Pension query
    const [q6] = await pool.query(`
        SELECT p.pension_id, CONCAT(e.first_name, ' ', e.last_name) as retiree, p.years_of_service, p.monthly_pension_amount, p.disbursement_status
        FROM Pension_Eligibility p
        JOIN Employees e ON p.emp_id = e.emp_id
        WHERE p.is_eligible = TRUE;
    `);
    console.log('✔ Query 6 (Eligible Retirees):', q6.length, 'eligible retirees');

    console.log('\nAll queries verified successfully with ZERO errors!');
    await pool.end();
}

verifyAll().catch(e => {
    console.error('FAILED:', e);
    process.exit(1);
});
