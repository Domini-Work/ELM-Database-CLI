import mysql from 'mysql2/promise';
import inquirer from 'inquirer';
import chalk from 'chalk';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { dbConfig, getPool } from './db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const COMPANY_LOGO = `
       /|\\
      / | \\ 
     /  |  \\
    /   |   \\
   /    |    \\
  /     |     \\
 /      |      \\
/_______|_______\\

 EMPLOYEE  MANAGER
 _________________
|        0        |
|       / \\       |
|      /   \\      |
|     /     \\     |
|    /       \\    |
|   /         \\   |
|  /           \\  |
| /             \\ |
|/               \\|
`;

let pool;

async function initDB() {
    pool = getPool();
    // Test connection
    const [rows] = await pool.query('SELECT 1 as test');
    return rows;
}

// ----------------------------------------------------
// 1. EMPLOYEE MANAGEMENT
// ----------------------------------------------------
async function viewEmployees() {
    const [rows] = await pool.query(`
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
        ORDER BY e.emp_id ASC;
    `);
    console.log(chalk.cyan(`\n=== Total Employees Registered: ${rows.length} ===`));
    console.table(rows);
}

async function viewEmployeeProfile() {
    const answer = await inquirer.prompt([
        { type: 'number', name: 'emp_id', message: 'Enter Employee ID to view 360° profile:' }
    ]);

    if (!answer.emp_id) return;

    const [empRows] = await pool.query(`
        SELECT 
            e.emp_id, e.first_name, e.last_name, e.email, e.phone, e.hire_date, e.status,
            d.name AS department_name, b.name AS branch_name, b.city AS branch_city,
            r.title AS role_title, r.employment_type, r.payment_model, r.support_requirements
        FROM Employees e
        LEFT JOIN Departments d ON e.department_id = d.department_id
        LEFT JOIN Branches b ON d.branch_id = b.branch_id
        LEFT JOIN Roles r ON e.role_id = r.role_id
        WHERE e.emp_id = ?;
    `, [answer.emp_id]);

    if (empRows.length === 0) {
        console.log(chalk.red(`No employee found with ID: ${answer.emp_id}`));
        return;
    }

    const emp = empRows[0];
    console.log(chalk.bold.green(`\n================== EMPLOYEE 360° DOSSIER ==================`));
    console.log(chalk.yellow(`ID: `) + emp.emp_id + ` | ` + chalk.yellow(`Name: `) + `${emp.first_name} ${emp.last_name}`);
    console.log(chalk.yellow(`Email: `) + emp.email + ` | ` + chalk.yellow(`Phone: `) + (emp.phone || 'N/A'));
    console.log(chalk.yellow(`Status: `) + chalk.bold(emp.status) + ` | ` + chalk.yellow(`Hire Date: `) + emp.hire_date.toISOString().slice(0, 10));
    console.log(chalk.yellow(`Department: `) + `${emp.department_name} (${emp.branch_name}, ${emp.branch_city})`);
    console.log(chalk.yellow(`Workforce Role: `) + `${emp.role_title} [Type: ${emp.employment_type}]`);
    console.log(chalk.yellow(`Compensation Model: `) + emp.payment_model);
    console.log(chalk.yellow(`Support / Equipment Requirements: `) + emp.support_requirements);

    // Current Salary & Benefits
    const [salRows] = await pool.query('SELECT base_salary, bonus, deductions, net_salary, payment_status, effective_date FROM Salaries WHERE emp_id = ? ORDER BY effective_date DESC LIMIT 1', [emp.emp_id]);
    const [benRows] = await pool.query('SELECT insurance_plan, insurance_coverage_amount, provident_fund_number, pf_employee_contribution, pf_employer_contribution, wellness_allowance FROM Benefits WHERE emp_id = ?', [emp.emp_id]);

    console.log(chalk.cyan(`\n--- Compensation & Benefits ---`));
    if (salRows.length > 0) {
        const s = salRows[0];
        console.log(`Base: $${s.base_salary} | Bonus: $${s.bonus} | Deductions: $${s.deductions} | Net Salary: $${s.net_salary} (${s.payment_status})`);
    } else {
        console.log(`No active salary schedule.`);
    }

    if (benRows.length > 0) {
        const b = benRows[0];
        console.log(`Insurance: ${b.insurance_plan} (Coverage: $${b.insurance_coverage_amount})`);
        console.log(`Provident Fund: ${b.provident_fund_number || 'N/A'} (Emp: $${b.pf_employee_contribution} | Org: $${b.pf_employer_contribution})`);
    }

    // Projects Allocated
    const [projRows] = await pool.query(`
        SELECT p.name, ep.role_in_project, ep.allocation_percentage, p.status
        FROM Employee_Projects ep
        JOIN Projects p ON ep.project_id = p.project_id
        WHERE ep.emp_id = ?;
    `, [emp.emp_id]);
    console.log(chalk.cyan(`\n--- Project Allocations ---`));
    if (projRows.length > 0) console.table(projRows);
    else console.log('No active project allocations.');

    // Assets Assigned
    const [assetRows] = await pool.query(`
        SELECT r.asset_tag, r.type, r.brand, r.model, a.issue_date, a.return_date, a.condition_on_issue, COALESCE(a.condition_on_return, 'Held by Employee') as status
        FROM Asset_Assignments a
        JOIN Resources r ON a.resource_id = r.resource_id
        WHERE a.emp_id = ?;
    `, [emp.emp_id]);
    console.log(chalk.cyan(`\n--- Company Assets History ---`));
    if (assetRows.length > 0) console.table(assetRows);
    else console.log('No assets assigned to this employee.');

    // Exit & Pension status if exited
    if (emp.status === 'Resigned' || emp.status === 'Terminated' || emp.status === 'Retired') {
        const [exitRows] = await pool.query('SELECT * FROM Exit_Records WHERE emp_id = ?', [emp.emp_id]);
        const [penRows] = await pool.query('SELECT * FROM Pension_Eligibility WHERE emp_id = ?', [emp.emp_id]);
        console.log(chalk.red(`\n--- Exit & Archival Dossier ---`));
        if (exitRows.length > 0) {
            const x = exitRows[0];
            console.log(`Exit Type: ${x.exit_type} | Exit Date: ${x.exit_date.toISOString().slice(0, 10)} | Resources Cleared: ${x.resources_cleared ? 'YES' : 'PENDING'}`);
            console.log(`Handover Notes: ${x.handover_notes}`);
        }
        if (penRows.length > 0) {
            const p = penRows[0];
            console.log(`Pension Status: ${p.disbursement_status} | Eligible: ${p.is_eligible ? 'YES' : 'NO'} | Monthly Amount: $${p.monthly_pension_amount}`);
        }
    }
    console.log(chalk.bold.green(`===========================================================\n`));
}

async function addEmployee() {
    const [depts] = await pool.query('SELECT department_id, name FROM Departments ORDER BY name');
    const [roles] = await pool.query('SELECT role_id, title, employment_type FROM Roles ORDER BY title');

    const deptChoices = depts.map(d => ({ name: `${d.department_id} - ${d.name}`, value: d.department_id }));
    const roleChoices = roles.map(r => ({ name: `${r.role_id} - ${r.title} (${r.employment_type})`, value: r.role_id }));

    const answers = await inquirer.prompt([
        { type: 'input', name: 'first_name', message: 'First Name:' },
        { type: 'input', name: 'last_name', message: 'Last Name:' },
        { type: 'input', name: 'email', message: 'Email:' },
        { type: 'input', name: 'phone', message: 'Phone Number (optional):' },
        { type: 'select', name: 'department_id', message: 'Select Department:', choices: deptChoices },
        { type: 'select', name: 'role_id', message: 'Select Role & Workforce Type:', choices: roleChoices },
        { type: 'input', name: 'hire_date', message: 'Hire Date (YYYY-MM-DD):', default: new Date().toISOString().slice(0, 10) },
        { type: 'select', name: 'status', message: 'Status:', choices: ['Active', 'On Leave'] }
    ]);

    try {
        const [result] = await pool.query(
            "INSERT INTO Employees (first_name, last_name, email, phone, department_id, role_id, hire_date, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            [answers.first_name, answers.last_name, answers.email, answers.phone || null, answers.department_id, answers.role_id, answers.hire_date, answers.status]
        );
        console.log(chalk.green(`\n✔ Employee added successfully! Assigned Employee ID: ${result.insertId}\n`));
    } catch (err) {
        console.log(chalk.red(`\n✖ Error adding employee: ${err.message}\n`));
    }
}

// ----------------------------------------------------
// 2. BEFORE JOINING: RECRUITMENT & UNIVERSITY PARTNERSHIPS
// ----------------------------------------------------
async function beforeJoiningMenu() {
    const answer = await inquirer.prompt([
        {
            type: 'select',
            name: 'action',
            message: 'Recruitment & University Placements (Before Joining):',
            choices: [
                'View University Placement Partnerships',
                'View Candidate Recruitment Pipeline',
                'Register New Candidate',
                'Update Candidate Selection Stage',
                '[Go Back]'
            ]
        }
    ]);

    switch (answer.action) {
        case 'View University Placement Partnerships': {
            const [rows] = await pool.query(`
                SELECT university_id AS ID, name AS University, location AS Location, tier AS Tier, contact_person AS Contact, contact_email AS Email, partnership_date AS Partnered, status AS Status
                FROM Universities
                ORDER BY university_id ASC;
            `);
            console.log(chalk.cyan(`\n=== University Campus Partnerships (${rows.length}) ===`));
            console.table(rows);
            break;
        }
        case 'View Candidate Recruitment Pipeline': {
            const [rows] = await pool.query(`
                SELECT 
                    c.candidate_id AS ID, c.name AS Candidate, c.email AS Email,
                    COALESCE(u.name, 'Direct Application') AS University,
                    c.applied_role AS Position,
                    c.selection_stage AS Stage,
                    c.interview_score AS Score,
                    c.status AS Status
                FROM Candidates c
                LEFT JOIN Universities u ON c.university_id = u.university_id
                ORDER BY c.candidate_id ASC;
            `);
            console.log(chalk.cyan(`\n=== Candidate Recruitment & Selection Registry (${rows.length}) ===`));
            console.table(rows);
            break;
        }
        case 'Register New Candidate': {
            const [univs] = await pool.query('SELECT university_id, name FROM Universities ORDER BY name');
            const univChoices = univs.map(u => ({ name: u.name, value: u.university_id }));
            univChoices.unshift({ name: 'None / Direct Off-Campus', value: null });

            const cand = await inquirer.prompt([
                { type: 'input', name: 'name', message: 'Candidate Full Name:' },
                { type: 'input', name: 'email', message: 'Candidate Email:' },
                { type: 'input', name: 'phone', message: 'Phone Number:' },
                { type: 'select', name: 'university_id', message: 'University Source:', choices: univChoices },
                { type: 'input', name: 'applied_role', message: 'Applied Position/Role:' },
                { type: 'select', name: 'selection_stage', message: 'Initial Selection Stage:', choices: ['Applied', 'Screening', 'Technical Round', 'HR Round'] },
                { type: 'number', name: 'interview_score', message: 'Initial Evaluation Score (0-10):', default: 8.0 }
            ]);

            try {
                const [res] = await pool.query(
                    "INSERT INTO Candidates (name, email, phone, university_id, applied_role, selection_stage, interview_score, application_date, status) VALUES (?, ?, ?, ?, ?, ?, ?, CURDATE(), 'In Process')",
                    [cand.name, cand.email, cand.phone, cand.university_id, cand.applied_role, cand.selection_stage, cand.interview_score]
                );
                console.log(chalk.green(`\n✔ Candidate registered successfully! ID: ${res.insertId}\n`));
            } catch (err) {
                console.log(chalk.red(`\n✖ Error registering candidate: ${err.message}\n`));
            }
            break;
        }
        case 'Update Candidate Selection Stage': {
            const [cands] = await pool.query("SELECT candidate_id, name, applied_role, selection_stage FROM Candidates WHERE status = 'In Process' ORDER BY candidate_id ASC");
            if (cands.length === 0) {
                console.log(chalk.yellow('No candidate currently in process.'));
                break;
            }
            const candChoices = cands.map(c => ({ name: `#${c.candidate_id} - ${c.name} (${c.applied_role}) [Current: ${c.selection_stage}]`, value: c.candidate_id }));
            candChoices.push({ name: '[Cancel]', value: null });

            const sel = await inquirer.prompt([
                { type: 'select', name: 'candidate_id', message: 'Select candidate to advance/update:', choices: candChoices }
            ]);
            if (!sel.candidate_id) break;

            const update = await inquirer.prompt([
                { type: 'select', name: 'new_stage', message: 'Updated Stage:', choices: ['Screening', 'Technical Round', 'HR Round', 'Offered', 'Hired', 'Rejected'] },
                { type: 'number', name: 'score', message: 'Updated Interview Score (0-10):' }
            ]);

            const finalStatus = update.new_stage === 'Hired' ? 'Hired' : (update.new_stage === 'Rejected' ? 'Rejected' : 'In Process');
            await pool.query(
                "UPDATE Candidates SET selection_stage = ?, interview_score = COALESCE(?, interview_score), status = ? WHERE candidate_id = ?",
                [update.new_stage, update.score || null, finalStatus, sel.candidate_id]
            );
            console.log(chalk.green(`\n✔ Candidate #${sel.candidate_id} updated to stage: ${update.new_stage} (Status: ${finalStatus})\n`));
            break;
        }
        case '[Go Back]':
            return;
    }
    await beforeJoiningMenu();
}

// ----------------------------------------------------
// 3. WORKFORCE PLANNING & RESOURCE ALLOCATION
// ----------------------------------------------------
async function workforcePlanningMenu() {
    const answer = await inquirer.prompt([
        {
            type: 'select',
            name: 'action',
            message: 'Workforce Planning & Resource Allocation:',
            choices: [
                'View Roles by Workforce Category (Fresher, Employee, Freelancer, Intern, Contractor)',
                'View Workforce Distribution Analytics',
                'View Payment Models & Support Requirements',
                '[Go Back]'
            ]
        }
    ]);

    switch (answer.action) {
        case 'View Roles by Workforce Category (Fresher, Employee, Freelancer, Intern, Contractor)': {
            const [rows] = await pool.query(`
                SELECT 
                    r.role_id AS ID,
                    r.title AS RoleTitle,
                    r.employment_type AS WorkforceType,
                    r.payment_model AS CompensationModel,
                    COUNT(e.emp_id) AS ActiveHeadcount
                FROM Roles r
                LEFT JOIN Employees e ON r.role_id = e.role_id AND e.status = 'Active'
                GROUP BY r.role_id, r.title, r.employment_type, r.payment_model
                ORDER BY r.employment_type, r.title;
            `);
            console.log(chalk.cyan(`\n=== Strategic Roles & Resource Allocation Catalog ===`));
            console.table(rows);
            break;
        }
        case 'View Workforce Distribution Analytics': {
            const [summary] = await pool.query(`
                SELECT 
                    r.employment_type AS WorkforceType,
                    COUNT(e.emp_id) AS TotalEmployees,
                    ROUND(AVG(s.base_salary), 2) AS AvgBasePay,
                    ROUND(SUM(s.base_salary), 2) AS TotalPayrollExpense
                FROM Roles r
                JOIN Employees e ON r.role_id = e.role_id
                LEFT JOIN Salaries s ON e.emp_id = s.emp_id
                GROUP BY r.employment_type
                ORDER BY TotalEmployees DESC;
            `);
            console.log(chalk.cyan(`\n=== Workforce Allocation & Expenditure Breakdown ===`));
            console.table(summary);
            break;
        }
        case 'View Payment Models & Support Requirements': {
            const [rows] = await pool.query(`
                SELECT 
                    title AS Role,
                    employment_type AS Category,
                    payment_model AS PaymentModel,
                    support_requirements AS SupportAndEquipment
                FROM Roles
                ORDER BY employment_type, title;
            `);
            console.log(chalk.cyan(`\n=== Support Requirements & Payment Standards ===`));
            console.table(rows);
            break;
        }
        case '[Go Back]':
            return;
    }
    await workforcePlanningMenu();
}

// ----------------------------------------------------
// 4. RESOURCES & ASSET TRACKING
// ----------------------------------------------------
async function assetTrackingMenu() {
    const answer = await inquirer.prompt([
        {
            type: 'select',
            name: 'action',
            message: 'Company Asset & Resource Tracking:',
            choices: [
                'View Complete Asset Inventory (Laptops, Mobiles, Chargers, etc.)',
                'View Active Asset Assignments',
                'Assign Resource to Employee',
                'Return Resource from Employee',
                '[Go Back]'
            ]
        }
    ]);

    switch (answer.action) {
        case 'View Complete Asset Inventory (Laptops, Mobiles, Chargers, etc.)': {
            const [rows] = await pool.query(`
                SELECT 
                    r.resource_id AS ID,
                    r.asset_tag AS Tag,
                    r.type AS Type,
                    CONCAT(r.brand, ' ', r.model) AS Device,
                    r.serial_number AS SerialNo,
                    r.status AS Status,
                    COALESCE(CONCAT(e.first_name, ' ', e.last_name), 'None') AS AssignedTo
                FROM Resources r
                LEFT JOIN Asset_Assignments a ON r.resource_id = a.resource_id AND a.return_date IS NULL
                LEFT JOIN Employees e ON a.emp_id = e.emp_id
                ORDER BY r.type, r.resource_id;
            `);
            console.log(chalk.cyan(`\n=== Company Hardware & Asset Inventory (${rows.length}) ===`));
            console.table(rows);
            break;
        }
        case 'View Active Asset Assignments': {
            const [rows] = await pool.query(`
                SELECT 
                    a.assignment_id AS AssignmentID,
                    r.asset_tag AS AssetTag,
                    r.type AS Type,
                    CONCAT(r.brand, ' ', r.model) AS Device,
                    e.emp_id AS EmpID,
                    CONCAT(e.first_name, ' ', e.last_name) AS AssignedEmployee,
                    a.issue_date AS IssueDate,
                    a.condition_on_issue AS ConditionIssued
                FROM Asset_Assignments a
                JOIN Resources r ON a.resource_id = r.resource_id
                JOIN Employees e ON a.emp_id = e.emp_id
                WHERE a.return_date IS NULL
                ORDER BY a.assignment_id ASC;
            `);
            console.log(chalk.cyan(`\n=== Currently Deployed Assets in the Field (${rows.length}) ===`));
            console.table(rows);
            break;
        }
        case 'Assign Resource to Employee': {
            const [avail] = await pool.query("SELECT resource_id, asset_tag, type, brand, model FROM Resources WHERE status = 'Available'");
            if (avail.length === 0) {
                console.log(chalk.yellow('\nNo available hardware assets in stock. All are currently deployed or in maintenance.\n'));
                break;
            }

            const [emps] = await pool.query("SELECT emp_id, first_name, last_name, status FROM Employees WHERE status = 'Active'");
            const assetChoices = avail.map(a => ({ name: `${a.asset_tag} - ${a.brand} ${a.model} (${a.type})`, value: a.resource_id }));
            const empChoices = emps.map(e => ({ name: `#${e.emp_id} - ${e.first_name} ${e.last_name}`, value: e.emp_id }));

            const assign = await inquirer.prompt([
                { type: 'select', name: 'resource_id', message: 'Select available asset to assign:', choices: assetChoices },
                { type: 'select', name: 'emp_id', message: 'Select active employee:', choices: empChoices },
                { type: 'input', name: 'issue_date', message: 'Issue Date (YYYY-MM-DD):', default: new Date().toISOString().slice(0, 10) },
                { type: 'input', name: 'condition_on_issue', message: 'Condition on Issue:', default: 'Good / Factory Inspected' }
            ]);

            try {
                await pool.query(
                    "INSERT INTO Asset_Assignments (resource_id, emp_id, issue_date, condition_on_issue) VALUES (?, ?, ?, ?)",
                    [assign.resource_id, assign.emp_id, assign.issue_date, assign.condition_on_issue]
                );
                await pool.query("UPDATE Resources SET status = 'Assigned' WHERE resource_id = ?", [assign.resource_id]);
                console.log(chalk.green('\n✔ Asset successfully assigned and logged!\n'));
            } catch (err) {
                console.log(chalk.red(`\n✖ Error assigning asset: ${err.message}\n`));
            }
            break;
        }
        case 'Return Resource from Employee': {
            const [activeAssigns] = await pool.query(`
                SELECT a.assignment_id, a.resource_id, r.asset_tag, CONCAT(r.brand, ' ', r.model) as device, e.emp_id, CONCAT(e.first_name, ' ', e.last_name) as emp_name
                FROM Asset_Assignments a
                JOIN Resources r ON a.resource_id = r.resource_id
                JOIN Employees e ON a.emp_id = e.emp_id
                WHERE a.return_date IS NULL;
            `);

            if (activeAssigns.length === 0) {
                console.log(chalk.yellow('\nNo active assignments found to return.\n'));
                break;
            }

            const choices = activeAssigns.map(a => ({
                name: `Assignment #${a.assignment_id}: ${a.asset_tag} (${a.device}) held by ${a.emp_name}`,
                value: a
            }));
            choices.push({ name: '[Cancel]', value: null });

            const sel = await inquirer.prompt([
                { type: 'select', name: 'selected', message: 'Select asset return record:', choices: choices }
            ]);
            if (!sel.selected) break;

            const ret = await inquirer.prompt([
                { type: 'input', name: 'return_date', message: 'Return Date (YYYY-MM-DD):', default: new Date().toISOString().slice(0, 10) },
                { type: 'input', name: 'condition', message: 'Condition on Return:', default: 'Returned in good working order' },
                { type: 'input', name: 'verified_by', message: 'Verified by (IT Staff Name):', default: 'IT Asset Admin' },
                { type: 'select', name: 'asset_status', message: 'Update Resource Status to:', choices: ['Available', 'Under Maintenance', 'Retired'] }
            ]);

            try {
                await pool.query(`
                    UPDATE Asset_Assignments 
                    SET return_date = ?, condition_on_return = ?, return_verified_by = ?
                    WHERE assignment_id = ?
                `, [ret.return_date, ret.condition, ret.verified_by, sel.selected.assignment_id]);

                await pool.query("UPDATE Resources SET status = ? WHERE resource_id = ?", [ret.asset_status, sel.selected.resource_id]);

                // Check if employee has any other unreturned assets
                const [remaining] = await pool.query("SELECT COUNT(*) as cnt FROM Asset_Assignments WHERE emp_id = ? AND return_date IS NULL", [sel.selected.emp_id]);
                if (remaining[0].cnt === 0) {
                    await pool.query("UPDATE Exit_Records SET resources_cleared = TRUE WHERE emp_id = ?", [sel.selected.emp_id]);
                    console.log(chalk.green(`\n✔ Resource returned! Employee #${sel.selected.emp_id} now has 0 unreturned company resources (Cleared).\n`));
                } else {
                    console.log(chalk.green(`\n✔ Resource returned! Note: Employee still holds ${remaining[0].cnt} other asset(s).\n`));
                }
            } catch (err) {
                console.log(chalk.red(`\n✖ Error returning resource: ${err.message}\n`));
            }
            break;
        }
        case '[Go Back]':
            return;
    }
    await assetTrackingMenu();
}

// ----------------------------------------------------
// 5. AFTER EXIT FROM COMPANY (EXIT MANAGEMENT & CLEARANCE)
// ----------------------------------------------------
async function exitManagementMenu() {
    const answer = await inquirer.prompt([
        {
            type: 'select',
            name: 'action',
            message: 'Exit Management & Resource Clearance Verification:',
            choices: [
                'View All Exit Records (Resignations, Terminations, Retirements)',
                'Verify Resource Clearance for Exited/Exiting Employees',
                'Record New Employee Exit (Offboarding)',
                '[Go Back]'
            ]
        }
    ]);

    switch (answer.action) {
        case 'View All Exit Records (Resignations, Terminations, Retirements)': {
            const [rows] = await pool.query(`
                SELECT 
                    x.exit_id AS ID,
                    e.emp_id AS EmpID,
                    CONCAT(e.first_name, ' ', e.last_name) AS Employee,
                    x.exit_type AS Type,
                    x.exit_date AS ExitDate,
                    x.notice_period_days AS NoticeDays,
                    x.exit_interview_completed AS InterviewDone,
                    CASE WHEN x.resources_cleared = 1 THEN 'CLEARED' ELSE 'PENDING RETURN' END AS AssetClearance,
                    x.handover_notes AS HandoverSummary
                FROM Exit_Records x
                JOIN Employees e ON x.emp_id = e.emp_id
                ORDER BY x.exit_date DESC;
            `);
            console.log(chalk.cyan(`\n=== Complete Employee Offboarding & Exit Records (${rows.length}) ===`));
            console.table(rows);
            break;
        }
        case 'Verify Resource Clearance for Exited/Exiting Employees': {
            const [pending] = await pool.query(`
                SELECT 
                    e.emp_id AS EmpID,
                    CONCAT(e.first_name, ' ', e.last_name) AS Employee,
                    e.status AS EmploymentStatus,
                    x.exit_type AS ExitType,
                    r.asset_tag AS HeldAssetTag,
                    CONCAT(r.brand, ' ', r.model) AS Device,
                    a.issue_date AS IssuedOn
                FROM Employees e
                JOIN Exit_Records x ON e.emp_id = x.emp_id
                JOIN Asset_Assignments a ON e.emp_id = a.emp_id AND a.return_date IS NULL
                JOIN Resources r ON a.resource_id = r.resource_id
                ORDER BY e.emp_id;
            `);

            if (pending.length === 0) {
                console.log(chalk.green('\n✔ All departed/exiting employees have 100% cleared and returned all company assets.\n'));
            } else {
                console.log(chalk.red.bold(`\n⚠ ACTION REQUIRED: ${pending.length} Unreturned Asset(s) Held by Exited Personnel:`));
                console.table(pending);
                console.log(chalk.yellow('Use "Resources & Asset Tracking -> Return Resource" to verify and check in these items.\n'));
            }
            break;
        }
        case 'Record New Employee Exit (Offboarding)': {
            const [activeEmps] = await pool.query("SELECT emp_id, first_name, last_name, status FROM Employees WHERE status IN ('Active', 'On Leave')");
            if (activeEmps.length === 0) {
                console.log(chalk.yellow('No active employees to offboard.'));
                break;
            }

            const choices = activeEmps.map(e => ({ name: `#${e.emp_id} - ${e.first_name} ${e.last_name}`, value: e.emp_id }));
            choices.push({ name: '[Cancel]', value: null });

            const sel = await inquirer.prompt([
                { type: 'select', name: 'emp_id', message: 'Select employee to initiate exit:', choices: choices }
            ]);
            if (!sel.emp_id) break;

            // Check if employee has pending assets
            const [unreturned] = await pool.query("SELECT COUNT(*) as cnt FROM Asset_Assignments WHERE emp_id = ? AND return_date IS NULL", [sel.emp_id]);
            const pendingAssets = unreturned[0].cnt;
            const resourcesCleared = pendingAssets === 0;

            if (!resourcesCleared) {
                console.log(chalk.yellow(`\nNotice: This employee currently has ${pendingAssets} unreturned company device(s).`));
                console.log(chalk.yellow(`Resource clearance will be flagged as PENDING until items are logged returned.\n`));
            }

            const exitData = await inquirer.prompt([
                { type: 'select', name: 'exit_type', message: 'Exit Classification:', choices: ['Resignation', 'Retirement', 'Termination'] },
                { type: 'input', name: 'exit_date', message: 'Exit Effective Date (YYYY-MM-DD):', default: new Date().toISOString().slice(0, 10) },
                { type: 'number', name: 'notice_period', message: 'Notice Period Served (Days):', default: 30 },
                { type: 'confirm', name: 'interview_completed', message: 'Exit interview & knowledge transfer completed?', default: true },
                { type: 'input', name: 'handover_notes', message: 'Handover & Knowledge Transfer Notes:' }
            ]);

            try {
                // Update employee status
                await pool.query("UPDATE Employees SET status = ? WHERE emp_id = ?", [exitData.exit_type, sel.emp_id]);

                // Insert exit record
                await pool.query(`
                    INSERT INTO Exit_Records (emp_id, exit_type, exit_date, notice_period_days, exit_interview_completed, resources_cleared, handover_notes)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                `, [sel.emp_id, exitData.exit_type, exitData.exit_date, exitData.notice_period, exitData.interview_completed, resourcesCleared, exitData.handover_notes]);

                // If retirement, check pension eligibility automatically
                if (exitData.exit_type === 'Retirement') {
                    const [sal] = await pool.query("SELECT base_salary FROM Salaries WHERE emp_id = ? ORDER BY effective_date DESC LIMIT 1", [sel.emp_id]);
                    const lastSal = sal.length > 0 ? sal[0].base_salary : 50000;
                    const monthlyPension = (lastSal * 0.50).toFixed(2);

                    await pool.query(`
                        INSERT INTO Pension_Eligibility (emp_id, is_eligible, years_of_service, last_drawn_salary, monthly_pension_amount, disbursement_status, pension_start_date)
                        VALUES (?, TRUE, 10.0, ?, ?, 'Active', ?)
                        ON DUPLICATE KEY UPDATE is_eligible = TRUE, disbursement_status = 'Active';
                    `, [sel.emp_id, lastSal, monthlyPension, exitData.exit_date]);
                    console.log(chalk.cyan(`✔ Retirement pension automatically scheduled: $${monthlyPension}/month.\n`));
                }

                console.log(chalk.green(`\n✔ Offboarding record created successfully for Employee #${sel.emp_id}!`));
                console.log(chalk.green(`Status updated to: ${exitData.exit_type} | Resource Clearance: ${resourcesCleared ? 'APPROVED' : 'PENDING RETURN'}\n`));
            } catch (err) {
                console.log(chalk.red(`\n✖ Error recording exit: ${err.message}\n`));
            }
            break;
        }
        case '[Go Back]':
            return;
    }
    await exitManagementMenu();
}

// ----------------------------------------------------
// 6. PENSION & BENEFITS MANAGEMENT
// ----------------------------------------------------
async function pensionBenefitsMenu() {
    const answer = await inquirer.prompt([
        {
            type: 'select',
            name: 'action',
            message: 'Pension, Provident Fund & Benefits:',
            choices: [
                'View Retirement Pension Roll & Eligibility Status',
                'View Employee Health Insurance & Provident Fund (PF) Registry',
                'Verify & Calculate Pension Eligibility for Employee',
                '[Go Back]'
            ]
        }
    ]);

    switch (answer.action) {
        case 'View Retirement Pension Roll & Eligibility Status': {
            const [rows] = await pool.query(`
                SELECT 
                    p.pension_id AS PensionID,
                    e.emp_id AS EmpID,
                    CONCAT(e.first_name, ' ', e.last_name) AS Retiree,
                    e.status AS EmploymentStatus,
                    p.years_of_service AS TenureYears,
                    p.last_drawn_salary AS LastSalary,
                    p.monthly_pension_amount AS MonthlyPension,
                    p.disbursement_status AS DisbursementStatus,
                    COALESCE(p.pension_start_date, 'N/A') AS StartDate
                FROM Pension_Eligibility p
                JOIN Employees e ON p.emp_id = e.emp_id
                ORDER BY p.is_eligible DESC, p.years_of_service DESC;
            `);
            console.log(chalk.cyan(`\n=== Pension Entitlement & Retirement Support Directory (${rows.length}) ===`));
            console.table(rows);
            break;
        }
        case 'View Employee Health Insurance & Provident Fund (PF) Registry': {
            const [rows] = await pool.query(`
                SELECT 
                    b.benefit_id AS ID,
                    CONCAT(e.first_name, ' ', e.last_name) AS Employee,
                    b.insurance_plan AS InsurancePlan,
                    b.insurance_coverage_amount AS CoverageLimit,
                    COALESCE(b.provident_fund_number, 'N/A (Contract)') AS PF_Number,
                    b.pf_employee_contribution AS Emp_PF_Monthly,
                    b.pf_employer_contribution AS Org_PF_Monthly,
                    b.wellness_allowance AS Wellness_Allowance
                FROM Benefits b
                JOIN Employees e ON b.emp_id = e.emp_id
                ORDER BY b.benefit_id ASC;
            `);
            console.log(chalk.cyan(`\n=== Organizational Benefits & Employee Support (${rows.length}) ===`));
            console.table(rows);
            break;
        }
        case 'Verify & Calculate Pension Eligibility for Employee': {
            const [emps] = await pool.query(`
                SELECT e.emp_id, CONCAT(e.first_name, ' ', e.last_name) as name, e.hire_date, e.status,
                       ROUND(DATEDIFF(COALESCE(x.exit_date, CURDATE()), e.hire_date) / 365.25, 1) as years_tenure
                FROM Employees e
                LEFT JOIN Exit_Records x ON e.emp_id = x.emp_id
                ORDER BY years_tenure DESC;
            `);

            const choices = emps.map(e => ({
                name: `#${e.emp_id} - ${e.name} (${e.status}, Tenure: ${e.years_tenure} yrs)`,
                value: e
            }));
            choices.push({ name: '[Cancel]', value: null });

            const sel = await inquirer.prompt([
                { type: 'select', name: 'target', message: 'Select employee to audit pension entitlement:', choices: choices }
            ]);
            if (!sel.target) break;

            const t = sel.target;
            const isRetiree = t.status === 'Retired';
            const meetsTenure = t.years_tenure >= 10.0;
            const eligible = isRetiree && meetsTenure;

            console.log(chalk.cyan(`\n--- Verification Audit for ${t.name} ---`));
            console.log(`Hire Date: ${t.hire_date.toISOString().slice(0, 10)} | Calculated Service: ${t.years_tenure} Years`);
            console.log(`Status: ${t.status} | Superannuation Criteria (>= 10 yrs & Retired): ${eligible ? chalk.green('MET') : chalk.red('NOT MET')}`);

            const [sal] = await pool.query("SELECT base_salary FROM Salaries WHERE emp_id = ? ORDER BY effective_date DESC LIMIT 1", [t.emp_id]);
            const lastSalary = sal.length > 0 ? sal[0].base_salary : 0;
            const pensionAmt = eligible ? (lastSalary * 0.50).toFixed(2) : 0.00;

            console.log(`Last Drawn Monthly Base Salary: $${lastSalary}`);
            console.log(`Calculated Monthly Pension Benefit: $${pensionAmt}\n`);

            const confirmSave = await inquirer.prompt([
                { type: 'confirm', name: 'save', message: 'Update / Store this pension audit record in database?', default: true }
            ]);

            if (confirmSave.save) {
                await pool.query(`
                    INSERT INTO Pension_Eligibility (emp_id, is_eligible, years_of_service, last_drawn_salary, monthly_pension_amount, disbursement_status, pension_start_date)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    ON DUPLICATE KEY UPDATE 
                        is_eligible = VALUES(is_eligible),
                        years_of_service = VALUES(years_of_service),
                        last_drawn_salary = VALUES(last_drawn_salary),
                        monthly_pension_amount = VALUES(monthly_pension_amount),
                        disbursement_status = VALUES(disbursement_status);
                `, [t.emp_id, eligible, t.years_tenure, lastSalary, pensionAmt, eligible ? 'Active' : 'Not Eligible', eligible ? new Date().toISOString().slice(0, 10) : null]);
                console.log(chalk.green(`✔ Pension audit saved successfully for Employee #${t.emp_id}.\n`));
            }
            break;
        }
        case '[Go Back]':
            return;
    }
    await pensionBenefitsMenu();
}

// ----------------------------------------------------
// 7. UNIVERSAL TABLE BROWSER
// ----------------------------------------------------
async function viewAnyTable() {
    try {
        const [tables] = await pool.query("SHOW TABLES");
        const tableNames = tables.map(t => Object.values(t)[0]);
        tableNames.push('[Go Back]');

        const answer = await inquirer.prompt([
            {
                type: 'select',
                name: 'tableName',
                message: 'Select a database table to browse:',
                choices: tableNames
            }
        ]);

        if (answer.tableName === '[Go Back]') return;

        const [rows] = await pool.query(`SELECT * FROM ${answer.tableName} LIMIT 50`);
        console.log(chalk.cyan(`\n=== Table: ${answer.tableName} (Showing first ${rows.length} rows) ===`));
        console.table(rows);
    } catch (err) {
        console.log(chalk.red(`\n✖ Error fetching table data: ${err.message}\n`));
    }
}

// ----------------------------------------------------
// 8. RESET / RE-SEED DATABASE
// ----------------------------------------------------
async function resetDatabase() {
    const confirm = await inquirer.prompt([
        {
            type: 'confirm',
            name: 'proceed',
            message: chalk.red.bold('WARNING: This will drop and re-create all tables with fresh mock data. Proceed?'),
            default: false
        }
    ]);

    if (!confirm.proceed) return;

    try {
        console.log(chalk.yellow('Re-running setup_db.sql...'));
        const sqlPath = path.join(__dirname, 'setup_db.sql');
        const sql = fs.readFileSync(sqlPath, 'utf8');
        await pool.query(sql);
        console.log(chalk.green('✔ Database re-seeded successfully with 15 normalized tables and consistent mock data!\n'));
    } catch (err) {
        console.log(chalk.red(`✖ Error re-seeding database: ${err.message}\n`));
    }
}

// ----------------------------------------------------
// MAIN MENU
// ----------------------------------------------------
async function mainMenu() {
    console.log(chalk.bold.blue('\n------------------------------------------------------------'));
    console.log(chalk.bold.white('          EMPLOYEE LIFECYCLE MANAGEMENT CLI TOOL           '));
    console.log(chalk.bold.blue('------------------------------------------------------------'));

    const answer = await inquirer.prompt([
        {
            type: 'select',
            name: 'action',
            message: 'Main Menu - Select an action or module:',
            choices: [
                '1. Employee Directory & 360° Profiles',
                '2. Add New Employee',
                '3. Before Joining: Recruitment & Campus Partnerships',
                '4. Workforce Planning & Resource Allocation',
                '5. Resources & Asset Tracking (Laptops, Mobiles, Chargers)',
                '6. Exit Management & Resource Clearance Verification',
                '7. Pension, Provident Fund & Benefits',
                '8. Universal Table Browser',
                '9. Reset / Re-seed Database',
                '10. Exit'
            ]
        }
    ]);

    switch (answer.action) {
        case '1. Employee Directory & 360° Profiles': {
            const sub = await inquirer.prompt([
                {
                    type: 'select',
                    name: 'empAction',
                    message: 'Employee Options:',
                    choices: [
                        'View All Employees Table',
                        'View Detailed 360° Employee Dossier',
                        '[Go Back]'
                    ]
                }
            ]);
            if (sub.empAction === 'View All Employees Table') await viewEmployees();
            else if (sub.empAction === 'View Detailed 360° Employee Dossier') await viewEmployeeProfile();
            break;
        }
        case '2. Add New Employee':
            await addEmployee();
            break;
        case '3. Before Joining: Recruitment & Campus Partnerships':
            await beforeJoiningMenu();
            break;
        case '4. Workforce Planning & Resource Allocation':
            await workforcePlanningMenu();
            break;
        case '5. Resources & Asset Tracking (Laptops, Mobiles, Chargers)':
            await assetTrackingMenu();
            break;
        case '6. Exit Management & Resource Clearance Verification':
            await exitManagementMenu();
            break;
        case '7. Pension, Provident Fund & Benefits':
            await pensionBenefitsMenu();
            break;
        case '8. Universal Table Browser':
            await viewAnyTable();
            break;
        case '9. Reset / Re-seed Database':
            await resetDatabase();
            break;
        case '10. Exit':
            console.log(chalk.green("\nThank you for using the Employee Management System. Goodbye!\n"));
            process.exit(0);
    }

    await mainMenu();
}

async function run() {
    console.log(chalk.yellow(COMPANY_LOGO));
    console.log(chalk.cyan(`Connecting to MySQL database '${dbConfig.database}' on ${dbConfig.host}...`));
    try {
        await initDB();
        console.log(chalk.green(`✔ Connected successfully to MySQL (${dbConfig.user}@${dbConfig.host}:${dbConfig.database})\n`));
        await mainMenu();
    } catch (err) {
        console.log(chalk.red(`✖ Failed to connect to database: ${err.message}`));
        console.log(chalk.yellow(`Check that MySQL is running and password matches '${dbConfig.password}' in db.js / process.env.DB_PASSWORD.`));
        process.exit(1);
    }
}

run();
