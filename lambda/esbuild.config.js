const esbuild = require('esbuild');
const fs = require('fs');
const path = require('path');
const archiver = require('archiver');

const functions = ['rest', 'graphql'];

async function build() {
  console.log('Building Lambda functions...');
  
  for (const func of functions) {
    console.log(`Building ${func} function...`);
    
    // Build with esbuild
    await esbuild.build({
      entryPoints: [`src/${func}/handler.ts`],
      bundle: true,
      platform: 'node',
      target: 'node18',
      outfile: `dist/${func}/handler.js`,
      external: ['aws-sdk'],
      logLevel: 'info'
    });

    // Create ZIP
    console.log(`Creating ZIP for ${func}...`);
    const output = fs.createWriteStream(`dist/${func}/lambda-${func}.zip`);
    const archive = archiver('zip', { zlib: { level: 9 } });
    
    archive.pipe(output);
    archive.directory(`dist/${func}/`, false);
    
    await archive.finalize();
    
    console.log(`✓ ${func} function built and zipped`);
  }
  
  console.log('All Lambda functions built successfully!');
}

build().catch(error => {
  console.error('Build failed:', error);
  process.exit(1);
});
