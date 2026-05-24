# Skills CLI Quick Reference

## Installation Status ✅

```
✅ find-skills           (vercel-labs/skills)
✅ mcp-builder           (anthropics/skills)
✅ frontend-design       (anthropics/skills)
✅ web-design-guidelines (vercel-labs/agent-skills)
❌ agent-browser         (does not exist)
```

---

## Quick Commands

### List Installed Skills
```bash
npx skills list --global
```

### Update All Skills
```bash
npx skills update --global
```

### Find New Skills
```bash
npx skills find
```

### Remove a Skill
```bash
npx skills remove <skill-name> --global
```

### Install Additional Skills
```bash
# From vercel-labs/skills
npx skills add vercel-labs/skills --skill <skill-name> --global --yes

# From anthropics/skills
npx skills add anthropics/skills --skill <skill-name> --global --yes

# From vercel-labs/agent-skills
npx skills add vercel-labs/agent-skills --skill <skill-name> --global --yes
```

---

## Available Skills by Repository

### vercel-labs/skills
- find-skills

### anthropics/skills
- algorithmic-art
- brand-guidelines
- canvas-design
- claude-api
- doc-coauthoring
- docx
- **frontend-design** ✅ (installed)
- internal-comms
- **mcp-builder** ✅ (installed)
- pdf
- pptx
- skill-creator
- slack-gif-creator
- theme-factory
- web-artifacts-builder
- webapp-testing
- xlsx

### vercel-labs/agent-skills
- composition-patterns
- deploy-to-vercel
- react-best-practices
- react-native-skills
- react-view-transitions
- vercel-cli-with-tokens
- vercel-optimize
- **web-design-guidelines** ✅ (installed)

---

## Automation Scripts

### Install All Skills
```bash
./install_skills.sh      # Linux/macOS/Git Bash
install_skills.bat       # Windows CMD
```

### Verify Installation
```bash
./verify_skills.sh       # Linux/macOS/Git Bash
verify_skills.bat        # Windows CMD
```

---

## Installation Location

```
~/.agents/skills/
  ├── find-skills/
  ├── frontend-design/
  ├── mcp-builder/
  └── web-design-guidelines/
```

Windows Path: `C:\Users\<username>\.agents\skills\`

---

## Troubleshooting

### Skills Not Found
```bash
# Clear npm cache
npm cache clean --force

# Reinstall skills
./install_skills.sh
```

### Update Skills CLI
```bash
npx skills@latest --version
```

### Check Node/npm
```bash
node --version    # Should be v14+ (currently v23.1.0)
npm --version     # Should be v6+ (currently v10.9.0)
```

---

## Resources

- Skills Homepage: https://skills.sh/
- Skills CLI: https://github.com/vercel-labs/skills
- Anthropic Skills: https://github.com/anthropics/skills
- Vercel Agent Skills: https://github.com/vercel-labs/agent-skills

---

**Last Updated**: 2026-05-24  
**Skills CLI Version**: 1.5.7  
**Status**: ✅ All Available Skills Installed
