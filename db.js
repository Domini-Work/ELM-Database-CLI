import mysql from 'mysql2/promise';

export const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '0000',
    database: process.env.DB_NAME || 'employee_management_db',
    multipleStatements: true,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
};

let pool = null;

export function getPool() {
    if (!pool) {
        pool = mysql.createPool(dbConfig);
    }
    return pool;
}

export async function createRawConnection(includeDatabase = true) {
    const config = {
        host: dbConfig.host,
        user: dbConfig.user,
        password: dbConfig.password,
        multipleStatements: true
    };
    if (includeDatabase) {
        config.database = dbConfig.database;
    }
    return await mysql.createConnection(config);
}

export default {
    dbConfig,
    getPool,
    createRawConnection
};
