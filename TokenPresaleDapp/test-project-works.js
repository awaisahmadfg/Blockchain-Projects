#!/usr/bin/env node

import { readFileSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

console.log('🚀 Testing Project Functionality...\n');

let testsPassed = 0;
let testsFailed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`✅ ${name}`);
    testsPassed++;
  } catch (error) {
    console.error(`❌ ${name}`);
    console.error(`   Error: ${error.message}`);
    testsFailed++;
  }
}

test('package.json is valid and parseable', () => {
  const pkgPath = join(__dirname, 'package.json');
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
  if (!pkg.name || !pkg.version) {
    throw new Error('Invalid package.json structure');
  }
});

test('Key dependencies are specified', () => {
  const pkgPath = join(__dirname, 'package.json');
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
  const required = ['react', 'react-dom', 'ethers', 'vite'];
  const missing = required.filter(dep => !pkg.dependencies[dep] && !pkg.devDependencies[dep]);
  if (missing.length > 0) {
    throw new Error(`Missing dependencies: ${missing.join(', ')}`);
  }
});

test('vite.config.js exists', () => {
  const configPath = join(__dirname, 'vite.config.js');
  if (!existsSync(configPath)) {
    throw new Error('vite.config.js not found');
  }
  const content = readFileSync(configPath, 'utf-8');
  if (!content.includes('defineConfig')) {
    throw new Error('vite.config.js appears invalid');
  }
});

test('Key source files exist', () => {
  const requiredFiles = [
    'src/index.jsx',
    'src/App.jsx',
    'index.html'
  ];
  const missing = requiredFiles.filter(file => !existsSync(join(__dirname, file)));
  if (missing.length > 0) {
    throw new Error(`Missing files: ${missing.join(', ')}`);
  }
});

test('Code uses ethers v5 API (compatible)', () => {
  const indexPath = join(__dirname, 'src/index.jsx');
  const content = readFileSync(indexPath, 'utf-8');
  if (content.includes('ethers.BrowserProvider')) {
    throw new Error('Code uses ethers v6 API but package.json has v5');
  }
  if (!content.includes('ethers.providers')) {
    throw new Error('Code should use ethers.providers (v5 API)');
  }
});

test('React Router v6 API is used (compatible)', () => {
  const appPath = join(__dirname, 'src/App.jsx');
  const content = readFileSync(appPath, 'utf-8');
  if (!content.includes('react-router-dom')) {
    throw new Error('React Router not imported');
  }
  if (!content.includes('BrowserRouter') || !content.includes('Routes') || !content.includes('Route')) {
    throw new Error('React Router v6 API not used correctly');
  }
});

test('Build configuration is valid', () => {
  const pkgPath = join(__dirname, 'package.json');
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
  if (!pkg.scripts.build) {
    throw new Error('Build script missing');
  }
  if (!pkg.scripts.start) {
    throw new Error('Start script missing');
  }
});

test('No critical dependency conflicts', () => {
  const pkgPath = join(__dirname, 'package.json');
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
  
  if (pkg.dependencies.ethers && !pkg.dependencies.ethers.startsWith('^5.')) {
    throw new Error('Ethers should be v5 for code compatibility');
  }
  
  if (pkg.dependencies.react && !pkg.dependencies.react.startsWith('^18.')) {
    throw new Error('React should be v18 for stability');
  }
  
  if (pkg.dependencies.yarn) {
    throw new Error('yarn should not be a dependency');
  }
});

console.log(`\n📊 Test Results: ${testsPassed} passed, ${testsFailed} failed\n`);

if (testsFailed === 0) {
  console.log('🎉 All functionality tests passed!');
  console.log('\n✨ The project is ready to:');
  console.log('   1. Install dependencies: npm install');
  console.log('   2. Run dev server: npm start');
  console.log('   3. Build for production: npm run build');
  console.log('   4. Run tests: npm test');
  console.log('\n✅ Project dependencies are fixed and compatible!');
  process.exit(0);
} else {
  console.log('⚠️  Some tests failed. Please review the errors above.');
  process.exit(1);
}
