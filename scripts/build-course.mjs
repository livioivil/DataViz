// No dependencies: node scripts/build-course.mjs [--check]
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const course = JSON.parse(fs.readFileSync(path.join(root, 'course.json'), 'utf8'));
const check = process.argv.includes('--check');
const escape = value => String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
const encodePath = value => value.split('/').map(encodeURIComponent).join('/');
const repo = course.repository.replace(/\/$/, '');
const raw = `${repo.replace('https://github.com/', 'https://raw.githubusercontent.com/')}/${encodeURIComponent(course.branch)}`;
const download = file => `${raw}/${encodePath(file)}`;
const zip = `${repo}/archive/refs/heads/${encodeURIComponent(course.branch)}.zip`;
const ids = new Set();
function validateFile(file) {
  if (typeof file !== 'string' || path.isAbsolute(file) || file.includes('\\') || file.split('/').includes('..')) {
    throw new Error(`Invalid path: ${file}`);
  }
  if (!fs.statSync(path.join(root, file)).isFile()) throw new Error(`Missing file: ${file}`);
}
for (const section of course.sections) {
  for (const item of section.items) {
    if (ids.has(item.id)) throw new Error(`Duplicate ID: ${item.id}`);
    ids.add(item.id);
    if (!item.title || !item.description) throw new Error(`Missing title or description: ${item.id}`);
    for (const format of ['html', 'pdf', 'source']) if (item[format]) validateFile(item[format]);
    if (!item.html && !item.pdf) throw new Error(`No materials for ${item.id}`);
  }
}
for (const dataset of course.datasets) validateFile(dataset.path);

const tables = course.sections.map(section => `## ${section.title}\n\n| Unit | Material | HTML | PDF | R Markdown source |\n| :-- | :-- | :-- | :-- | :-- |\n${section.items.map(item => `| ${item.id} | **${item.title}**<br>${item.description} | ${item.html ? `[Download HTML](${download(item.html)})` : '—'} | ${item.pdf ? `[View](${encodePath(item.pdf)}) · [Download PDF](${download(item.pdf)})` : '—'} | ${item.source ? `[Rmd](${encodePath(item.source)})` : '—'} |`).join('\n')}`).join('\n\n');
const readme = `<!-- Generated from course.json by scripts/build-course.mjs. -->
# ${course.title}

Course materials for **Data Visualization**, taught by ${course.author}.
The course is updated throughout the term: units, activities, and materials may be added or revised.

## Using the materials

- **HTML:** select “Download HTML” and save the file from your browser (Ctrl+S / Cmd+S, or “Save link as”). Then open it in a browser. The current HTML files embed graphics and styling; some external links require Internet access.
- **PDF:** select “View” to read it on GitHub, or “Download PDF” and use your browser's download command.
- **Entire course:** [download the repository ZIP](${zip}) and extract it before opening the files. Keep the data/ folder and repository structure intact when working with the code.
- **Browsable catalogue:** after downloading, open [index.html](index.html) in your browser to browse the materials and download individual files. GitHub's repository view displays HTML as source code.

You do not need R to read HTML or PDF files. To complete the coding activities, you need basic knowledge of R and descriptive statistics, R, and an editor such as RStudio. Open [DataViz.Rproj](DataViz.Rproj) from the course folder and follow the package requirements listed in each unit.

## Learning objectives

- Choose charts that match the data and analysis questions.
- Interpret counts, proportions, scales, and statistical summaries.
- Discuss perception, colour, and clarity in visual communication.
- Produce reproducible exploratory reports and explain your choices.

${tables}

## Activity datasets

| Dataset | Use | Download |
| :-- | :-- | :-- |
${course.datasets.map(dataset => `| **${dataset.title}** | ${dataset.description} | [CSV](${download(dataset.path)}) |`).join('\n')}

These CSV files are used in teaching activities. Consult the relevant unit for the scenario, variable definitions, and limits of interpretation. Record the version of the materials you use so that your analysis can be reproduced.

To report an error, open an [Issue](${repo}/issues) and specify the unit, file, and problem. Do not include personal data or other students' work.
`;

function actions(item) {
  return [
    item.html && `<a href="${escape(encodePath(item.html))}">Read HTML</a><a href="${escape(encodePath(item.html))}" download>Download HTML</a>`,
    item.pdf && `<a href="${escape(encodePath(item.pdf))}" download>Download PDF</a>`,
    item.source && `<a href="${escape(encodePath(item.source))}" download>Rmd source</a>`
  ].filter(Boolean).join('');
}
const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escape(course.title)} · Course materials</title>
<style>
:root{font-family:system-ui,sans-serif;color:#172c3c;background:#f3f6f8;line-height:1.6}
body{margin:0}main{max-width:1060px;margin:auto;padding:32px 24px 64px}header{padding:24px 0 16px}
h1{font-size:clamp(2rem,5vw,3.5rem);line-height:1.15;margin:12px 0}h2{margin-top:40px}h3{margin:0;font-size:1.2rem}
a{color:#07568a;text-underline-offset:3px}a:focus-visible,summary:focus-visible{outline:3px solid #bd5615;outline-offset:4px}
.meta{color:#466074}.intro{max-width:760px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,310px),1fr));gap:16px}
.card{background:white;border:1px solid #d3dfe6;border-radius:12px;padding:22px;display:flex;flex-direction:column}
.code{font-size:.85rem;font-weight:700;color:#466074;margin:0 0 8px}.card p{margin:12px 0 18px}
.actions{display:flex;flex-wrap:wrap;gap:9px;margin-top:auto}.actions a{border:1px solid #a3bac9;border-radius:6px;padding:7px 12px;font-size:.9rem;background:#f5fafc}
nav{display:flex;flex-wrap:wrap;gap:12px;margin:20px 0}details{background:white;border:1px solid #d3dfe6;padding:16px;border-radius:8px}summary{cursor:pointer;font-weight:600}
footer{margin-top:40px;border-top:1px solid #d3dfe6;padding-top:18px;font-size:.9rem}
@media print{body{background:white}.card{break-inside:avoid}.actions,nav{display:none}}
</style>
</head>
<body><main>
<header><p class="meta">${escape(course.author)}</p><h1>${escape(course.title)}</h1>
<p class="intro">Course lessons, activities, and datasets. Follow the sequence of units and consult further examples as needed. Materials are updated throughout the course.</p>
<nav aria-label="Quick links"><a href="#units">Units and materials</a><a href="#datasets">CSV datasets</a><a href="${escape(zip)}">Download everything (ZIP)</a><a href="${escape(repo)}">GitHub repository</a></nav>
<details><summary>Reading and downloading files</summary><p>“Read HTML” opens the lesson in your browser. “Download” buttons save individual files; if your browser opens a document, use its save command. To work with R, download and extract the entire repository, keeping the original folders. Consult feedback and worked examples after your own attempt.</p><p>You do not need R to read HTML and PDF files. The instructor will provide the schedule, submission instructions, and assessment criteria.</p></details></header>
<div id="units">
${course.sections.map(section => `<section aria-label="${escape(section.title)}"><h2>${escape(section.title)}</h2><div class="grid">${section.items.map(item => `<article class="card"><p class="code">${escape(item.id)}</p><h3>${escape(item.title)}</h3><p>${escape(item.description)}</p><div class="actions">${actions(item)}</div></article>`).join('\n')}</div></section>`).join('\n')}
</div>
<section id="datasets"><h2>Activity datasets</h2><div class="grid">${course.datasets.map(dataset => `<article class="card"><h3>${escape(dataset.title)}</h3><p>${escape(dataset.description)}</p><div class="actions"><a href="${escape(encodePath(dataset.path))}" download>Download CSV</a></div></article>`).join('\n')}</div></section>
<footer>Course materials are updated throughout the term · <a href="${escape(repo)}/issues">Report an error</a></footer>
</main></body></html>
`;

for (const [file, content] of [['README.md', readme], ['index.html', html]]) {
  const target = path.join(root, file);
  if (check) {
    if (!fs.existsSync(target) || fs.readFileSync(target, 'utf8') !== content) throw new Error(`${file} is out of date: run node scripts/build-course.mjs`);
  } else fs.writeFileSync(target, content, 'utf8');
}
console.log(`${check ? 'Checked' : 'Generated'} README.md and index.html: ${ids.size} materials, ${course.datasets.length} datasets. All catalogue files exist.`);
