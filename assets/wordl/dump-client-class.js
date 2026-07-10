const fs = require('fs');
const path = require('path');

const app3dJsPath = path.join(__dirname, 'assets', 'App3D-patched.js');
const content = fs.readFileSync(app3dJsPath, 'utf8');

const index = content.indexOf('class ln');
if (index !== -1) {
  console.log("class ln found at index:", index);
  const snippet = content.substring(index, index + 2000);
  console.log("Snippet:\n", snippet);
} else {
  console.log("class ln NOT found");
}
