const fs = require('fs');
const path = require('path');

const app3dJsPath = path.join(__dirname, 'assets', 'App3D-patched.js');
const content = fs.readFileSync(app3dJsPath, 'utf8');

const index = content.indexOf('client$1=');
if (index !== -1) {
  console.log("client$1 found at index:", index);
  const snippet = content.substring(index - 200, index + 800);
  console.log("Snippet:\n", snippet);
} else {
  // Let's search for "client$1 = " with space
  const index2 = content.indexOf('client$1 =');
  if (index2 !== -1) {
    console.log("client$1 found at index (spaced):", index2);
    const snippet = content.substring(index2 - 200, index2 + 800);
    console.log("Snippet:\n", snippet);
  } else {
    // Search case-insensitive substring "absolutePath"
    const index3 = content.indexOf('absolutePath');
    if (index3 !== -1) {
      console.log("absolutePath found at index:", index3);
      const snippet = content.substring(index3 - 200, index3 + 800);
      console.log("Snippet:\n", snippet);
    } else {
      console.log("client$1 and absolutePath NOT found");
    }
  }
}
