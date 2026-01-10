# Backend Scripts

Utility scripts for backend management and deployment.

## Scripts

### reset-db.sh (Future)
Reset database to clean state
```bash
./scripts/reset-db.sh
```

### deploy-migration.sh (Future)
Deploy a specific migration
```bash
./scripts/deploy-migration.sh 003_add_favorites.sql
```

### backup-db.sh (Future)
Create database backup
```bash
./scripts/backup-db.sh
```

### seed-dev.sh (Future)
Load development seed data
```bash
./scripts/seed-dev.sh
```

## Creating Scripts

Scripts should:
- Be executable: `chmod +x script-name.sh`
- Have error handling
- Print status messages
- Support dry-run mode

### Template

```bash
#!/bin/bash
set -e  # Exit on error

echo "Running script..."

# Your logic here

echo "✅ Done!"
```

## Note

Most operations can be done via Supabase Dashboard. Scripts are optional but useful for:
- Automation
- CI/CD pipelines
- Batch operations
- Development workflow
