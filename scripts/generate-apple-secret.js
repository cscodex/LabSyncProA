#!/usr/bin/env node

/**
 * Apple OAuth Client Secret Generator for LabSyncPro
 * 
 * This script generates a JWT token required for Apple Sign-In authentication.
 * You need to provide your Apple Developer credentials.
 */

const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');

// Colors for console output
const colors = {
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  reset: '\x1b[0m'
};

function log(color, message) {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function printUsage() {
  console.log('\n🍎 Apple OAuth Client Secret Generator for LabSyncPro\n');
  console.log('Usage:');
  console.log('  node generate-apple-secret.js [options]\n');
  console.log('Options:');
  console.log('  --key-file <path>     Path to your Apple private key (.p8 file)');
  console.log('  --team-id <id>        Your Apple Team ID (10 characters)');
  console.log('  --key-id <id>         Your Apple Key ID (10 characters)');
  console.log('  --client-id <id>      Your Apple Service ID (e.g., com.company.app.web)');
  console.log('  --help                Show this help message\n');
  console.log('Example:');
  console.log('  node generate-apple-secret.js \\');
  console.log('    --key-file ./AuthKey_ABC123DEF4.p8 \\');
  console.log('    --team-id ABC123DEF4 \\');
  console.log('    --key-id ABC123DEF4 \\');
  console.log('    --client-id com.yourcompany.labsyncpro.web\n');
}

function parseArgs() {
  const args = process.argv.slice(2);
  const config = {};
  
  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--key-file':
        config.keyFile = args[++i];
        break;
      case '--team-id':
        config.teamId = args[++i];
        break;
      case '--key-id':
        config.keyId = args[++i];
        break;
      case '--client-id':
        config.clientId = args[++i];
        break;
      case '--help':
        printUsage();
        process.exit(0);
        break;
      default:
        log('red', `Unknown option: ${args[i]}`);
        printUsage();
        process.exit(1);
    }
  }
  
  return config;
}

function validateConfig(config) {
  const errors = [];
  
  if (!config.keyFile) {
    errors.push('Missing --key-file parameter');
  } else if (!fs.existsSync(config.keyFile)) {
    errors.push(`Key file not found: ${config.keyFile}`);
  }
  
  if (!config.teamId) {
    errors.push('Missing --team-id parameter');
  } else if (config.teamId.length !== 10) {
    errors.push('Team ID must be exactly 10 characters');
  }
  
  if (!config.keyId) {
    errors.push('Missing --key-id parameter');
  } else if (config.keyId.length !== 10) {
    errors.push('Key ID must be exactly 10 characters');
  }
  
  if (!config.clientId) {
    errors.push('Missing --client-id parameter');
  } else if (!config.clientId.includes('.')) {
    errors.push('Client ID should be in reverse domain format (e.g., com.company.app.web)');
  }
  
  return errors;
}

function generateClientSecret(config) {
  try {
    log('blue', '📖 Reading private key file...');
    const privateKey = fs.readFileSync(config.keyFile, 'utf8');
    
    log('blue', '🔐 Generating JWT token...');
    const now = Math.floor(Date.now() / 1000);
    const expiration = now + (6 * 30 * 24 * 60 * 60); // 6 months
    
    const payload = {
      iss: config.teamId,
      iat: now,
      exp: expiration,
      aud: 'https://appleid.apple.com',
      sub: config.clientId,
    };
    
    const header = {
      kid: config.keyId,
      alg: 'ES256',
    };
    
    const clientSecret = jwt.sign(payload, privateKey, {
      algorithm: 'ES256',
      header: header,
    });
    
    return clientSecret;
  } catch (error) {
    throw new Error(`Failed to generate client secret: ${error.message}`);
  }
}

function main() {
  try {
    log('green', '🍎 Apple OAuth Client Secret Generator for LabSyncPro');
    log('green', '================================================\n');
    
    const config = parseArgs();
    
    if (Object.keys(config).length === 0) {
      log('yellow', 'No arguments provided. Use --help for usage information.\n');
      printUsage();
      process.exit(1);
    }
    
    log('blue', '✅ Validating configuration...');
    const errors = validateConfig(config);
    
    if (errors.length > 0) {
      log('red', '\n❌ Configuration errors:');
      errors.forEach(error => log('red', `  • ${error}`));
      console.log();
      printUsage();
      process.exit(1);
    }
    
    log('green', '✅ Configuration valid!\n');
    
    log('blue', 'Configuration:');
    log('blue', `  Team ID: ${config.teamId}`);
    log('blue', `  Key ID: ${config.keyId}`);
    log('blue', `  Client ID: ${config.clientId}`);
    log('blue', `  Key File: ${config.keyFile}\n`);
    
    const clientSecret = generateClientSecret(config);
    
    log('green', '🎉 Apple Client Secret generated successfully!\n');
    
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('Apple Client Secret (copy this to your .env.local file):');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(clientSecret);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    log('yellow', '📝 Next steps:');
    log('yellow', '  1. Copy the client secret above');
    log('yellow', '  2. Add it to your .env.local file:');
    log('yellow', '     APPLE_CLIENT_SECRET=<paste_client_secret_here>');
    log('yellow', '  3. Add your Apple Client ID:');
    log('yellow', `     NEXT_PUBLIC_APPLE_CLIENT_ID=${config.clientId}`);
    log('yellow', '  4. Configure Apple provider in Supabase dashboard');
    log('yellow', '  5. Test Apple Sign-In in your application\n');
    
    log('green', '✅ Apple OAuth setup is ready!');
    
  } catch (error) {
    log('red', `\n❌ Error: ${error.message}`);
    process.exit(1);
  }
}

// Check if jsonwebtoken is installed
try {
  require('jsonwebtoken');
} catch (error) {
  log('red', '❌ Missing dependency: jsonwebtoken');
  log('yellow', 'Please install it by running: npm install jsonwebtoken');
  process.exit(1);
}

main();
