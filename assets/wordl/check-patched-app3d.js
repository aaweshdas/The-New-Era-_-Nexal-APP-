const fs = require('fs');
const path = require('path');

const app3dJsPath = path.join(__dirname, 'assets', 'App3D-patched.js');
if (fs.existsSync(app3dJsPath)) {
  const content = fs.readFileSync(app3dJsPath, 'utf8');
  const index = content.indexOf('dracoworker');
  if (index !== -1) {
    console.log("dracoworker found at index:", index);
    const snippet = content.substring(Math.max(0, index - 100), Math.min(content.length, index + 100));
    console.log("Snippet:", snippet);
  } else {
    console.log("dracoworker NOT found in App3D-patched.js");
  }
} else {
  console.log("App3D-patched.js NOT found!");
}
