const fs = require('fs');
const path = require('path');

const webglJsPath = path.join(__dirname, 'assets', 'webgl-patched.js');
const content = fs.readFileSync(webglJsPath, 'utf8');

const regex = /https:\/\/messenger\.abeto\.co/g;
const matches = [];
let match;
while ((match = regex.exec(content)) !== null) {
  const index = match.index;
  const snippet = content.substring(Math.max(0, index - 50), Math.min(content.length, index + 80));
  matches.push({ index, snippet });
}

console.log(`Found ${matches.length} occurrences in webgl-patched.js:`);
matches.forEach((m, i) => {
  console.log(`Occurrence ${i + 1}: ${m.snippet}`);
});
