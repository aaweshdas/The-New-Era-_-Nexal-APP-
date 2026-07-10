const fs = require('fs');
const path = require('path');
const https = require('https');

const app3dJsPath = path.join(__dirname, 'assets', 'App3D-BLRWK1h9.js');

if (!fs.existsSync(app3dJsPath)) {
  console.error("App3D-BLRWK1h9.js not found!");
  process.exit(1);
}

let content = fs.readFileSync(app3dJsPath, 'utf8');

// Find all matches for dracoworker in App3D-BLRWK1h9.js
const regex = /https:\/\/messenger\.abeto\.co\/assets\/dracoworker-[a-zA-Z0-9_\-]+\.js/g;
const matches = content.match(regex);

if (matches) {
  console.log("Found matches:", matches);
  
  // Download each matched worker file and replace in JS content
  for (const workerUrl of matches) {
    const workerFilename = path.basename(workerUrl);
    const localDestPath = path.join(__dirname, 'assets', workerFilename);
    
    console.log(`Downloading worker from ${workerUrl}...`);
    
    // Download
    https.get(workerUrl, response => {
      if (response.statusCode === 200) {
        const file = fs.createWriteStream(localDestPath);
        response.pipe(file);
        file.on('finish', () => {
          file.close();
          console.log(`Successfully saved worker to ${localDestPath}`);
          
          // Replace URL in file content with relative path
          content = content.replace(workerUrl, `./assets/${workerFilename}`);
          fs.writeFileSync(app3dJsPath, content, 'utf8');
          console.log(`Patched ${workerUrl} to ./assets/${workerFilename} in App3D-BLRWK1h9.js`);
        });
      } else {
        console.error(`Failed to download worker: HTTP status ${response.statusCode}`);
      }
    }).on('error', err => {
      console.error(`Error downloading worker: ${err.message}`);
    });
  }
} else {
  console.log("No dracoworker URL matches found in App3D-BLRWK1h9.js. Searching case-insensitive for dracoworker substring...");
  const index = content.indexOf("dracoworker");
  if (index !== -1) {
    console.log("Found 'dracoworker' at index:", index);
    const snippet = content.substring(Math.max(0, index - 100), Math.min(content.length, index + 100));
    console.log("Snippet:", snippet);
  } else {
    console.log("Dracoworker substring not found.");
  }
}
