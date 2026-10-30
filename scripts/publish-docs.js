// Builds the docs and publishes them to kashtheking.com/init/: the built site is committed into the
// `init/` folder of the KashTheKing.github.io repo (GitHub Pages serves it). Same flow as library and
// infinite-ocean. Run: npm run publish:docs
const { execFileSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const SITE_REPO = process.env.SITE_REPO || "https://github.com/KashTheKing/KashTheKing.github.io.git";
const SITE_DIR = "init";
const root = path.resolve(__dirname, "..");
const out = path.join(root, "build", "site-repo");
const built = path.join(root, "build", "docs");
const git = (args, cwd) => execFileSync("git", args, { cwd, stdio: "inherit" });

execFileSync("node", [path.join(__dirname, "build-docs.js")], { cwd: root, stdio: "inherit" });

if (!fs.existsSync(path.join(out, ".git"))) {
	fs.mkdirSync(path.dirname(out), { recursive: true });
	git(["clone", "--depth", "1", SITE_REPO, out], root);
} else {
	git(["fetch", "--depth", "1", "origin"], out);
	git(["reset", "--hard", "origin/main"], out);
}
const target = path.join(out, SITE_DIR);
fs.rmSync(target, { recursive: true, force: true });
fs.cpSync(built, target, { recursive: true });
fs.writeFileSync(path.join(target, ".nojekyll"), "");

const short = execFileSync("git", ["rev-parse", "--short", "HEAD"], { cwd: root }).toString().trim();
git(["add", "-A", SITE_DIR], out);
try {
	execFileSync("git", ["diff", "--cached", "--quiet"], { cwd: out });
	console.log("site already up to date");
} catch {
	git(["commit", "-q", "-m", `Init docs from init ${short}`], out);
	git(["push", "-q", "origin", "HEAD:main"], out);
	console.log("published to https://kashtheking.com/init/");
}
