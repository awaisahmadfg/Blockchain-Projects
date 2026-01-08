#!/usr/bin/env node

import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

console.log('🧪 Running Dependency Verification Tests...\n');

const tests = [];
let passed = 0;
let failed = 0;

function test(name, fn) {
  tests.push({ name, fn });
}

function runTests() {
  tests.forEach(({ name, fn }) => {
    try {
      fn();
      console.log(`✅ ${name}`);
      passed++;
    } catch (error) {
      console.error(`❌ ${name}`);
      console.error(`   Error: ${error.message}`);
      failed++;
    }
  });

  console.log(`\n📊 Results: ${passed} passed, ${failed} failed`);
  return failed === 0;
}

test('package.json is valid JSON', () => {
  const pkgPath = join(__dirname, 'package.json');
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
  if (!pkg.dependencies || !pkg.devDependencies) {
    throw new Error('package.json missing dependencies or devDependencies');
  }
});

test('ethers version is v5 (compatible with code)', () => {
  const pkgPath = join(__dirname, 'package.json');
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
  const ethersVersion = pkg.dependencies.ethers;
  if (!ethersVersion || !ethersVersion.startsWith('^5.')) {
    throw new Error(`Expected ethers v5, found: ${ethersVersion}`);
  }
});

test('React version is v18 (stable)', () => {
  const pkgPath = join(__dirname, 'package.json');
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
  const reactVersion = pkg.dependencies.react;
  if (!reactVersion || !reactVersion.startsWith('^18.')) {
    throw new Error(`Expected React v18, found: ${reactVersion}`);
  }
});

test('Jest is in devDependencies', () => {
  const pkgPath = join(__dirname, 'package.json');
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
  if (!pkg.devDependencies.jest) {
    throw new Error('Jest is missing from devDependencies');
  }
});

test('yarn is not in dependencies', () => {
  const pkgPath = join(__dirname, 'package.json');
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
  if (pkg.dependencies.yarn) {
    throw new Error('yarn should not be in dependencies');
  }
});

test('Vite version is v5 (stable)', () => {
  const pkgPath = join(__dirname, 'package.json');
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
  const viteVersion = pkg.devDependencies.vite;
  if (!viteVersion || !viteVersion.startsWith('^5.')) {
    throw new Error(`Expected Vite v5, found: ${viteVersion}`);
  }
});

test('React Router version is v6 (stable)', () => {
  const pkgPath = join(__dirname, 'package.json');
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
  const routerVersion = pkg.dependencies['react-router-dom'];
  if (!routerVersion || !routerVersion.startsWith('^6.')) {
    throw new Error(`Expected React Router v6, found: ${routerVersion}`);
  }
});

test('Key source files exist', () => {
  const keyFiles = [
    'src/index.jsx',
    'src/App.jsx',
    'vite.config.js',
  ];
  
  keyFiles.forEach(file => {
    try {
      readFileSync(join(__dirname, file), 'utf-8');
    } catch (error) {
      throw new Error(`Missing required file: ${file}`);
    }
  });
});

test('Code uses ethers v5 API (providers)', () => {
  const indexPath = join(__dirname, 'src/index.jsx');
  const content = readFileSync(indexPath, 'utf-8');
  if (!content.includes('ethers.providers.Web3Provider')) {
    throw new Error('Code should use ethers.providers.Web3Provider (v5 API)');
  }
});

const success = runTests();

if (success) {
  console.log('\n🎉 All dependency verification tests passed!');
  console.log('\n📝 Next steps:');
  console.log('   1. Run: npm install');
  console.log('   2. Run: npm start (to test dev server)');
  console.log('   3. Run: npm run build (to test production build)');
  process.exit(0);
} else {
  console.log('\n⚠️  Some tests failed. Please review the errors above.');
  process.exit(1);
}
