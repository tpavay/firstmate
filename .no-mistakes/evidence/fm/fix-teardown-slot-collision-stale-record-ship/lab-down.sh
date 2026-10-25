#!/usr/bin/env bash
# lab-down.sh: kill the lab tmux server, remove lab Claude trust entries (same code as bin/fm-live-lab.sh forget_claude_entries), remove the lab.
. /tmp/fmsc-current; CLAUDE_STORE=$HOME/.claude.json
forget_claude_entries() {  # remove every project entry at or under ROOT; prints the count
  [ -e "$CLAUDE_STORE" ] || { echo 0; return 0; }
  node - "$CLAUDE_STORE" "$ROOT" "${ROOT#/private}" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const [link, ...roots] = process.argv.slice(2);
const store = fs.realpathSync(link);
const stat = fs.statSync(store);
if (!stat.isFile() || stat.uid !== process.getuid()) {
  console.error(`error: ${store} is not a regular file this user owns`); process.exit(1);
}
const inLab = (key) => roots.some((r) => key === r || key.startsWith(`${r}/`));
const fingerprint = (buf) => crypto.createHash("sha256").update(buf).digest("hex");
for (let attempt = 0; attempt < 3; attempt += 1) {
  const original = fs.readFileSync(store);
  const root = JSON.parse(original.toString("utf8"));
  const projects = root.projects;
  if (projects === undefined) { console.log(0); process.exit(0); }
  if (projects === null || typeof projects !== "object" || Array.isArray(projects)) {
    console.error(`error: ${store} has a non-object "projects" value`); process.exit(1);
  }
  const removed = Object.keys(projects).filter(inLab);
  if (removed.length === 0) { console.log(0); process.exit(0); }
  const kept = Object.keys(projects).filter((k) => !inLab(k));
  for (const key of removed) delete projects[key];
  const tmp = path.join(path.dirname(store), `.claude.json.fm-live-lab.${process.pid}.${crypto.randomBytes(8).toString("hex")}`);
  fs.writeFileSync(tmp, `${JSON.stringify(root, null, 2)}\n`, { mode: fs.statSync(store).mode & 0o777, flag: "wx" });
  let renamed = false;
  try {
    if (fingerprint(fs.readFileSync(store)) !== fingerprint(original)) continue;
    fs.renameSync(tmp, store);
    renamed = true;
  } finally {
    if (!renamed) fs.rmSync(tmp, { force: true });
  }
  const back = Object.keys(JSON.parse(fs.readFileSync(store, "utf8")).projects || {});
  if (back.some(inLab) || kept.some((k) => !back.includes(k))) {
    console.error(`error: ${store} did not keep exactly the non-lab entries`); process.exit(1);
  }
  console.log(removed.length);
  process.exit(0);
}
console.error(`error: ${store} kept changing while lab entries were being removed`);
process.exit(1);
NODE
}
env -u TMUX TMUX_TMPDIR="$TMUX_DIR" tmux kill-server 2>/dev/null; echo "trust entries removed: $(forget_claude_entries)"
"$LAB/bin/fm-lab-home.sh" teardown "$LAB" 2>/dev/null; rm -rf /tmp/fm-$A /tmp/fm-$B "$ROOT"; echo "lab removed: $ROOT"
