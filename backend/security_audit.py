#!/usr/bin/env python3
"""
Security Audit Script
Checks for common security vulnerabilities and misconfigurations.
"""
import os
import re
import sys
from pathlib import Path

class SecurityAudit:
    def __init__(self):
        self.issues = []
        self.warnings = []
        self.passed = []
    
    def check_secret_key(self):
        """Check if default SECRET_KEY is being used."""
        print("\n🔐 Checking Secret Key Security...")
        
        with open('auth.py', 'r') as f:
            content = f.read()
            if 'your_secret_key_change_in_production' in content:
                self.issues.append("❌ CRITICAL: Default SECRET_KEY is still in use!")
                print("  ❌ CRITICAL: Using default SECRET_KEY")
                print("     → Must use environment variable or secure key")
                return False
            else:
                self.passed.append("✅ SECRET_KEY appears secure")
                print("  ✅ SECRET_KEY configuration looks secure")
                return True
    
    def check_cors_configuration(self):
        """Check CORS settings."""
        print("\n🌐 Checking CORS Configuration...")
        
        with open('main.py', 'r') as f:
            content = f.read()
            if 'allow_origins=["*"]' in content:
                self.warnings.append("⚠️ CORS allows all origins (*)") 
                print("  ⚠️ WARNING: CORS allows all origins")
                print("     → Should restrict to specific domains in production")
                return False
            else:
                self.passed.append("✅ CORS configuration is restricted")
                print("  ✅ CORS is properly configured")
                return True
    
    def check_sql_injection(self):
        """Check for potential SQL injection vulnerabilities."""
        print("\n💉 Checking SQL Injection Protection...")
        
        issues_found = False
        for filepath in Path('routes').rglob('*.py'):
            with open(filepath, 'r') as f:
                content = f.read()
                # Check for string concatenation in queries
                if re.search(r'\.execute\(["\'].*\+.*["\']', content):
                    self.issues.append(f"❌ Potential SQL injection in {filepath}")
                    print(f"  ❌ Potential SQL injection risk in {filepath}")
                    issues_found = True
        
        if not issues_found:
            self.passed.append("✅ No SQL injection vulnerabilities found")
            print("  ✅ Using parameterized queries (ORM)")
        
        return not issues_found
    
    def check_password_hashing(self):
        """Verify password hashing is used."""
        print("\n🔒 Checking Password Security...")
        
        with open('auth.py', 'r') as f:
            content = f.read()
            if 'bcrypt' in content and 'pwd_context.hash' in content:
                self.passed.append("✅ Password hashing with bcrypt")
                print("  ✅ Using bcrypt for password hashing")
                return True
            else:
                self.issues.append("❌ Password hashing not properly configured")
                print("  ❌ Password hashing issue detected")
                return False
    
    def check_token_expiration(self):
        """Check JWT token expiration settings."""
        print("\n⏰ Checking Token Expiration...")
        
        with open('auth.py', 'r') as f:
            content = f.read()
            match = re.search(r'ACCESS_TOKEN_EXPIRE_MINUTES\s*=\s*(\d+)', content)
            if match:
                minutes = int(match.group(1))
                if minutes <= 60:
                    self.passed.append(f"✅ Token expiration: {minutes} minutes")
                    print(f"  ✅ Token expires after {minutes} minutes")
                    return True
                else:
                    self.warnings.append(f"⚠️ Token expiration too long: {minutes} minutes")
                    print(f"  ⚠️ Token expiration is quite long: {minutes} minutes")
                    return False
    
    def check_https_enforcement(self):
        """Check for HTTPS enforcement."""
        print("\n🔐 Checking HTTPS/TLS Configuration...")
        
        # This should be enforced at deployment level
        self.warnings.append("⚠️ HTTPS should be enforced at deployment")
        print("  ⚠️ Ensure HTTPS is enforced in production deployment")
        print("     → Use reverse proxy (nginx) with SSL/TLS")
        return False
    
    def check_input_validation(self):
        """Check for input validation using Pydantic."""
        print("\n✅ Checking Input Validation...")
        
        with open('schemas.py', 'r') as f:
            content = f.read()
            if 'BaseModel' in content:
                self.passed.append("✅ Using Pydantic for input validation")
                print("  ✅ Pydantic models used for input validation")
                return True
            else:
                self.issues.append("❌ No input validation framework detected")
                print("  ❌ Missing input validation")
                return False
    
    def check_error_handling(self):
        """Check for information disclosure in error messages."""
        print("\n🚨 Checking Error Handling...")
        
        issues_found = False
        for filepath in Path('routes').rglob('*.py'):
            with open(filepath, 'r') as f:
                content = f.read()
                # Check for exception details being exposed
                if re.search(r'detail=.*str\(e\)', content):
                    self.warnings.append(f"⚠️ Exception details exposed in {filepath}")
                    print(f"  ⚠️ Exception details may be exposed in {filepath}")
                    issues_found = True
        
        if not issues_found:
            self.passed.append("✅ Error handling looks good")
            print("  ✅ Error messages appear safe")
        
        return not issues_found
    
    def check_rate_limiting(self):
        """Check for rate limiting implementation."""
        print("\n🚦 Checking Rate Limiting...")
        
        with open('main.py', 'r') as f:
            content = f.read()
            if 'SlowAPI' in content or 'RateLimiter' in content:
                self.passed.append("✅ Rate limiting implemented")
                print("  ✅ Rate limiting is configured")
                return True
            else:
                self.warnings.append("⚠️ No rate limiting detected")
                print("  ⚠️ No rate limiting implementation found")
                print("     → Consider adding rate limiting for production")
                return False
    
    def check_database_security(self):
        """Check database security settings."""
        print("\n🗄️ Checking Database Security...")
        
        with open('database.py', 'r') as f:
            content = f.read()
            
            # Check for hardcoded credentials
            if re.search(r'postgresql://\w+:\w+@', content):
                self.issues.append("❌ Database credentials in code")
                print("  ❌ Database credentials hardcoded")
                return False
            
            # Check for SQLite in production
            if 'sqlite' in content.lower():
                self.warnings.append("⚠️ Using SQLite (consider PostgreSQL for production)")
                print("  ⚠️ Using SQLite database")
                print("     → Consider PostgreSQL for production")
            
            self.passed.append("✅ No hardcoded database credentials")
            print("  ✅ Database configuration looks safe")
            return True
    
    def generate_report(self):
        """Generate security audit report."""
        print("\n" + "="*70)
        print("📋 SECURITY AUDIT SUMMARY")
        print("="*70)
        
        print(f"\n✅ Passed Checks: {len(self.passed)}")
        for item in self.passed:
            print(f"  {item}")
        
        if self.warnings:
            print(f"\n⚠️ Warnings: {len(self.warnings)}")
            for item in self.warnings:
                print(f"  {item}")
        
        if self.issues:
            print(f"\n❌ Critical Issues: {len(self.issues)}")
            for item in self.issues:
                print(f"  {item}")
        
        print("\n" + "="*70)
        print("🛡️ SECURITY RECOMMENDATIONS")
        print("="*70)
        print("""
1. SECRET_KEY: Use environment variable
   export SECRET_KEY=$(openssl rand -hex 32)

2. CORS: Restrict to specific origins in production
   allow_origins=["https://yourdomain.com"]

3. HTTPS: Always use HTTPS in production
   Deploy behind nginx with SSL/TLS certificate

4. Rate Limiting: Add rate limiting middleware
   pip install slowapi

5. Database: Use PostgreSQL in production
   Better performance and security than SQLite

6. Monitoring: Implement logging and monitoring
   Track suspicious activities and errors

7. Dependencies: Regularly update dependencies
   pip list --outdated

8. Backup: Implement regular database backups
   Automated backup strategy
        """)
        
        return len(self.issues) == 0
    
    def run_all_checks(self):
        """Run all security checks."""
        print("\n" + "="*70)
        print("🛡️ COMPREHENSIVE SECURITY AUDIT")
        print("="*70)
        
        try:
            self.check_secret_key()
            self.check_cors_configuration()
            self.check_sql_injection()
            self.check_password_hashing()
            self.check_token_expiration()
            self.check_https_enforcement()
            self.check_input_validation()
            self.check_error_handling()
            self.check_rate_limiting()
            self.check_database_security()
            
            passed = self.generate_report()
            
            if passed:
                print("\n✅ Security audit completed - No critical issues!")
                return 0
            else:
                print("\n⚠️ Security audit completed - Critical issues found!")
                return 1
            
        except Exception as e:
            print(f"\n❌ Error during security audit: {e}")
            import traceback
            traceback.print_exc()
            return 1

if __name__ == "__main__":
    os.chdir(os.path.dirname(__file__))
    auditor = SecurityAudit()
    sys.exit(auditor.run_all_checks())
