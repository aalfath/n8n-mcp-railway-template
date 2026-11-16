// Usage: node merge-db.js NEW_DB OLD_DB
// Clears the sample rows that ship in the release database's workflow_versions
// table, then copies the rows from OLD_DB (if given) into NEW_DB, matching
// columns by name so a schema change between releases doesn't break the copy.
'use strict';
const Database = require('/app/node_modules/better-sqlite3');
const [newPath, oldPath] = process.argv.slice(2);

const db = new Database(newPath);
const cols = (schema) =>
  db.prepare(`PRAGMA ${schema}.table_info(workflow_versions)`).all().map((c) => c.name);

db.exec('DELETE FROM main.workflow_versions');
let copied = 0;
if (oldPath) {
  db.prepare('ATTACH DATABASE ? AS old').run(oldPath);
  const oldCols = new Set(cols('old'));
  const common = cols('main').filter((c) => oldCols.has(c)).map((c) => `"${c}"`).join(', ');
  if (oldCols.size && common) {
    copied = db.prepare(`INSERT INTO main.workflow_versions (${common}) SELECT ${common} FROM old.workflow_versions`).run().changes;
  }
  db.exec('DETACH DATABASE old');
}
db.pragma('wal_checkpoint(TRUNCATE)');
db.pragma('journal_mode = DELETE');
db.close();
console.log(`railway-start: database ready, ${copied} workflow snapshot(s) carried over`);
