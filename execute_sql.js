import mysql from 'mysql2/promise';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { dbConfig } from './db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function main() {
    let connection;
    try {
        console.log(`Connecting to MySQL at ${dbConfig.host} as ${dbConfig.user}...`);
        connection = await mysql.createConnection({
            host: dbConfig.host,
            user: dbConfig.user,
            password: dbConfig.password,
            multipleStatements: true
        });

        console.log("Connected successfully.");
        const sqlPath = path.join(__dirname, 'setup_db.sql');
        console.log(`Reading SQL script from: ${sqlPath}`);
        const sql = fs.readFileSync(sqlPath, 'utf8');

        console.log("Executing SQL schema and mock data scripts...");
        await connection.query(sql);
        console.log("\x1b[32m✔ Database 'employee_management_db' and all tables set up successfully!\x1b[0m\n");

        // Verify tables and counts
        const [tables] = await connection.query(`
            SELECT table_name, table_rows 
            FROM information_schema.tables 
            WHERE table_schema = 'employee_management_db'
            ORDER BY table_name;
        `);

        console.log("=== Table Summary ===");
        console.table(tables);

    } catch (error) {
        console.error("\x1b[31mError setting up database:\x1b[0m", error);
        process.exit(1);
    } finally {
        if (connection) {
            await connection.end();
        }
    }
}

main();
