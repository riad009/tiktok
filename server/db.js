const { Pool } = require('pg');

const pool = new Pool({
  connectionString: 'postgresql://neondb_owner:npg_g5GbUDtLA3ST@ep-blue-bush-af4kxytm-pooler.c-2.us-west-2.aws.neon.tech/neondb?sslmode=require',
  ssl: { rejectUnauthorized: false },
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
});

module.exports = pool;
