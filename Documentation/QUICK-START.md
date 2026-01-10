# CoinFlip Backend Implementation - Quick Start Guide

## 📚 Documentation Files

You have 3 main documentation files:

1. **Backend-Implementation-Plan.md** - Sprint 11 in complete detail
2. **Backend-Sprints-12-18.md** - Sprints 12-18 overview
3. **QUICK-START.md** - This file (how to use the docs)

---

## 🚀 How to Execute the Plan

### Step 1: Prepare Your Environment

```bash
# 1. Ensure you're on a clean develop branch
cd /Users/avinash/Code/CoinFlip
git checkout develop
git status  # Should show no changes

# 2. Create a backup (optional but recommended)
git branch backup/before-backend-$(date +%Y%m%d)
```

### Step 2: Create Supabase Account

1. Go to https://supabase.com
2. Sign up / Log in
3. Click "New Project"
4. Fill in:
   - Project name: `coinflip`
   - Database password: (generate strong password, save it!)
   - Region: Choose closest to you
   - Click "Create project"
5. Wait 2-3 minutes for project to initialize

### Step 3: Get Your Credentials

Once project is ready:

1. Go to Project Settings (gear icon) → API
2. Copy these two values:
   ```
   Project URL: https://xxxxx.supabase.co
   anon public key: eyJhbGciOiJI... (very long key)
   ```
3. Keep these safe, you'll need them for Task 11.1

### Step 4: Execute Sprint 11

Now you're ready to start! Here's how:

#### Task 11.1: Supabase Setup

```bash
# 1. Create branch
git checkout -b feature/sprint-11-task-1-supabase-setup

# 2. Open Backend-Implementation-Plan.md
# 3. Navigate to "Task 11.1: Supabase Project Setup"
# 4. Copy this exact prompt:
```

**Prompt to copy:**
```
Execute Task 11.1: Supabase Project Setup

Steps:
1. Create a new Supabase project at https://supabase.com/dashboard
2. Install Supabase Swift SDK via SPM in Xcode
3. Create Services/SupabaseService.swift with singleton client
4. Add environment variables for Supabase URL and anon key
5. Initialize Supabase in CoinFlipApp.swift
6. Create unit tests to verify Supabase client initialization

Acceptance Criteria:
- Supabase project created and accessible
- Swift SDK installed (package: https://github.com/supabase-community/supabase-swift)
- SupabaseService.swift created with shared instance
- Environment variables configured
- App initializes Supabase on launch
- Tests verify client can be instantiated

Files to Create:
- Services/SupabaseService.swift
- Services/Config/EnvironmentConfig.swift
- Tests/Unit/SupabaseServiceTests.swift

Tests Required:
1. testSupabaseClientInitialization() - Verify client can be created
2. testSupabaseURLConfiguration() - Verify URL is valid
3. testSupabaseKeyConfiguration() - Verify anon key is set
```

```bash
# 5. Paste prompt to Claude (me!)
# 6. I will create all the files and code
# 7. Follow my instructions to:
#    - Add Supabase URL and key to EnvironmentConfig.swift
#    - Run tests
# 8. When tests pass, commit:

git add .
git commit -m "Task 11.1: Supabase setup complete"
git tag sprint-11-task-1-complete
git push origin feature/sprint-11-task-1-supabase-setup --tags
```

#### Task 11.2: Database Schema

```bash
# 1. Create branch from develop
git checkout develop
git checkout -b feature/sprint-11-task-2-database-schema

# 2. Find "Task 11.2: Database Schema Design" in docs
# 3. Copy the prompt:
```

**Prompt to copy:**
```
Execute Task 11.2: Database Schema Design

Steps:
1. Create SQL schema for users, portfolios, holdings, transactions tables
2. Execute SQL in Supabase SQL Editor
3. Set up Row Level Security (RLS) policies
4. Create database indexes for performance
5. Create Swift models matching database schema
6. Write tests to verify schema structure

(... rest of prompt from docs)
```

```bash
# 4. Paste to Claude
# 5. I will provide the SQL and updated models
# 6. You execute SQL in Supabase dashboard
# 7. Run tests
# 8. Commit and tag
```

#### Task 11.3: Service Layer

Same pattern - find prompt, paste to Claude, execute, test, commit.

#### Task 11.4: Testing & Merge

```bash
# After all tasks complete:
git checkout feature/sprint-11-backend-foundation
git merge feature/sprint-11-task-1-supabase-setup
git merge feature/sprint-11-task-2-database-schema
git merge feature/sprint-11-task-3-service-layer

# Run all tests
xcodebuild test -scheme CoinFlip

# If all pass:
git checkout develop
git merge feature/sprint-11-backend-foundation
git tag sprint-11-complete
git push origin develop --tags
```

---

## 🧪 Testing Strategy

### For Each Task:

**1. Unit Tests (automatic)**
```bash
xcodebuild test -scheme CoinFlip \
  -only-testing:CoinFlipTests/[TestClass]
```

**2. Manual Testing (in app)**
- Build and run: `Cmd+R`
- Test the specific feature
- Verify it works as expected

**3. Integration Testing (optional)**
```bash
xcodebuild test -scheme CoinFlip \
  -only-testing:CoinFlipTests/IntegrationTests
```

### Test Coverage Target
- **Minimum:** 70%
- **Target:** 80%
- **Excellent:** 90%+

---

## 🔄 Rollback Instructions

### If Something Goes Wrong

**Rollback to previous task:**
```bash
# List all tags
git tag | grep sprint-11

# Rollback to specific task
git checkout sprint-11-task-1-complete

# Create new branch from there
git checkout -b feature/sprint-11-task-2-retry
```

**Rollback entire sprint:**
```bash
# Go back to before Sprint 11
git checkout develop
git reset --hard sprint-10-complete

# Restart Sprint 11
git checkout -b feature/sprint-11-backend-foundation
```

**Keep backup of current work:**
```bash
# Before resetting, save your work
git checkout -b backup/sprint-11-failed-attempt
git push origin backup/sprint-11-failed-attempt

# Then rollback
git checkout develop
git reset --hard sprint-10-complete
```

---

## 📋 Sprint Execution Checklist

### Before Each Sprint
- [ ] Read sprint overview in docs
- [ ] Understand the goal
- [ ] Check prerequisites
- [ ] Create sprint branch

### For Each Task
- [ ] Create task branch
- [ ] Copy prompt from docs
- [ ] Paste prompt to Claude
- [ ] Execute Claude's instructions
- [ ] Run tests
- [ ] Verify tests pass
- [ ] Commit with descriptive message
- [ ] Tag task as complete
- [ ] Push branch and tags

### After Each Sprint
- [ ] Merge all task branches
- [ ] Run full test suite
- [ ] Manual testing in app
- [ ] Create sprint summary
- [ ] Merge to develop
- [ ] Tag sprint as complete
- [ ] Push to origin

---

## 🎯 Sprint Overview

### Quick Reference

| Sprint | Duration | Goal | Difficulty |
|--------|----------|------|------------|
| 11 | 3-5 days | Backend setup | Medium |
| 12 | 4-6 days | Authentication | Medium-Hard |
| 13 | 3-4 days | Real crypto prices | Easy-Medium |
| 14 | 4-5 days | Portfolio sync | Medium |
| 15 | 2-3 days | Settings | Easy |
| 16 | 3-4 days | Leaderboard | Medium |
| 17 | 2-3 days | Caching | Easy-Medium |
| 18 | 3-5 days | Production | Medium |

**Total:** 24-35 days (4-7 weeks)

---

## 💡 Pro Tips

### 1. Work in Small Chunks
Don't try to do an entire sprint in one day. Do one task per day.

### 2. Test Frequently
Run tests after every file change. Don't wait until the end.

### 3. Commit Often
Commit after each small change. Makes rollback easier.

### 4. Use Developer Settings
Toggle between Mock/API mode to test without backend.

### 5. Keep Documentation Updated
Update sprint summaries as you go.

### 6. Ask Questions
If a prompt is unclear, ask Claude for clarification.

---

## 🚨 Common Issues & Solutions

### Issue: Supabase SDK won't install
**Solution:**
```bash
# In Xcode:
# File → Packages → Reset Package Caches
# Then try adding package again
```

### Issue: Tests failing with "module not found"
**Solution:**
```bash
# Clean build folder
Cmd+Shift+K

# Rebuild
Cmd+B
```

### Issue: RLS policies blocking queries
**Solution:**
- Check you're signed in
- Verify policies in Supabase dashboard
- Check auth.uid() matches user

### Issue: Git conflicts
**Solution:**
```bash
# See conflicts
git status

# Resolve conflicts in Xcode
# Then:
git add .
git commit -m "Resolve merge conflicts"
```

---

## 📞 Need Help?

### During Implementation

**Stuck on a task?**
```
Ask Claude: "I'm stuck on Sprint 11, Task 2.
The error is: [paste error].
How do I fix this?"
```

**Need clarification?**
```
Ask Claude: "Can you explain Task 11.3
in more detail? Specifically the
DataServiceFactory part."
```

**Want to skip a task?**
```
Ask Claude: "Can I skip Sprint 12, Task 3
(Passkey) and do it later?"
```

### Progress Check

**See where you are:**
```bash
# View completed sprints
git tag | grep complete

# View current branch
git branch --show-current

# View recent commits
git log --oneline -10
```

---

## ✅ You're Ready!

You now have:
- ✅ Complete implementation plan
- ✅ Copy-paste prompts for every task
- ✅ Test requirements documented
- ✅ Rollback strategy
- ✅ This quick start guide

### Next Step

Open `Backend-Implementation-Plan.md` and start with Sprint 11, Task 1.

**First prompt to execute:**
```
Execute Task 11.1: Supabase Project Setup
```

Good luck! 🚀
