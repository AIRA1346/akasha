#!/usr/bin/env node
/**
 * Registry poster URL health check.
 * Usage: node tool/archive/tmdb_poster_legacy/check_poster_urls.mjs [--root assets/registry|akasha-db]
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, '..');

const args = process.argv.slice(2);
const rootFlag = args.find((a) => a.startsWith('--root='));
const registryRoot = path.resolve(
  projectRoot,
  rootFlag ? rootFlag.split('=')[1] : 'assets/registry',
);

const shardsDir = path.join(registryRoot, 'shards');
if (!fs.existsSync(shardsDir)) {
  console.error(`Shards not found: ${shardsDir}`);
  process.exit(1);
}

/** @type {{ workId: string, posterPath: string, shard: string }[]} */
const entries = [];

for (const category of fs.readdirSync(shardsDir)) {
  const categoryDir = path.join(shardsDir, category);
  if (!fs.statSync(categoryDir).isDirectory()) continue;
  for (const file of fs.readdirSync(categoryDir)) {
    if (!file.endsWith('.json')) continue;
    const shardPath = `shards/${category}/${file}`;
    const data = JSON.parse(fs.readFileSync(path.join(categoryDir, file), 'utf8'));
    for (const [key, work] of Object.entries(data)) {
      const poster = work?.posterPath;
      if (typeof poster === 'string' && poster.startsWith('http')) {
        entries.push({
          workId: work.workId ?? key,
          posterPath: poster,
          shard: shardPath,
        });
      }
    }
  }
}

const concurrency = 8;
let ok = 0;
let fail = 0;
/** @type {{ workId: string, status: number|string, posterPath: string, shard: string }[]} */
const failures = [];

async function checkOne(entry) {
  try {
    const res = await fetch(entry.posterPath, {
      method: 'HEAD',
      redirect: 'follow',
      signal: AbortSignal.timeout(12_000),
    });
    if (res.ok) {
      ok++;
      return;
    }
    fail++;
    failures.push({
      workId: entry.workId,
      status: res.status,
      posterPath: entry.posterPath,
      shard: entry.shard,
    });
  } catch (err) {
    fail++;
    failures.push({
      workId: entry.workId,
      status: err?.message ?? 'error',
      posterPath: entry.posterPath,
      shard: entry.shard,
    });
  }
}

for (let i = 0; i < entries.length; i += concurrency) {
  const batch = entries.slice(i, i + concurrency);
  await Promise.all(batch.map(checkOne));
  process.stdout.write(
    `\rChecked ${Math.min(i + concurrency, entries.length)}/${entries.length}`,
  );
}

console.log(`\n\nRoot: ${registryRoot}`);
console.log(`OK: ${ok}  FAIL: ${fail}  TOTAL: ${entries.length}`);

if (failures.length > 0) {
  console.log('\nFailures:');
  for (const f of failures) {
    console.log(`  ${f.workId} [${f.status}] ${f.shard}`);
    console.log(`    ${f.posterPath}`);
  }
  process.exit(1);
}
