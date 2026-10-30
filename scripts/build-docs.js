// Builds the docs site into build/docs: writes docs/guides/templates.md from templates/, runs Moonwave,
// then copies the AI files next to it (served at kashtheking.com/init/SKILL.md, /llms.txt, /templates/*).
const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const read = (file) => fs.readFileSync(path.join(root, file), "utf8");
const templates = fs.readdirSync(path.join(root, "templates")).sort();

// Templates page: one section per template, code straight from the files
let page = `---
sidebar_position: 4
title: Templates
---

# Templates

Every module type, ready to copy. Replace \`_SNIPPET_\` with your name (the plugin's buttons do it for you).
Raw files for AI: \`https://kashtheking.com/init/templates/<File>\`.
`;
for (const file of templates) {
	const lang = file.endsWith(".json") ? "json" : "lua";
	page += `\n## ${file.replace(/\.(luau|model\.json)$/, "")}\n\n[Raw](pathname:///init/templates/${file})\n\n\`\`\`${lang}\n${read(`templates/${file}`).trim()}\n\`\`\`\n`;
}
fs.writeFileSync(path.join(root, "docs", "guides", "templates.md"), page);

execSync("moonwave build --code src/Init/init.luau --out-dir build/docs", { cwd: root, stdio: "inherit" });
const out = path.join(root, "build", "docs");
if (!fs.existsSync(path.join(out, "index.html"))) throw new Error("moonwave build produced no index.html");

fs.copyFileSync(path.join(root, "skills", "init", "SKILL.md"), path.join(out, "SKILL.md"));
fs.mkdirSync(path.join(out, "templates"), { recursive: true });
for (const file of templates) fs.copyFileSync(path.join(root, "templates", file), path.join(out, "templates", file));

// llms.txt: the skill plus every guide, for AIs that read one page
const docs = ["intro.md", "install/no-code.md", "install/with-ai.md", "install/wally.md", "install/model.md",
	"guides/lifecycle.md", "guides/entries.md", "guides/settings.md", "guides/troubleshooting.md", "migrating.md"];
const strip = (md) => md.replace(/^---[\s\S]*?---\n/, "");
fs.writeFileSync(path.join(out, "llms.txt"), [read("skills/init/SKILL.md"), ...docs.map((d) => strip(read(`docs/${d}`)))].join("\n\n---\n\n"));
console.log("docs built in build/docs");
