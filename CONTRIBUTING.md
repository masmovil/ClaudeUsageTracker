# Contributing to Claude Usage Tracker

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## 📜 License Notice

**Copyright © 2025 Sergio Bañuls**

This project is licensed under a **Personal Use License (Non-Commercial)**. By contributing, you agree that:
- Your contributions will be licensed under the same Personal Use License
- Sergio Bañuls retains copyright as the original author
- All contributions must respect the non-commercial nature of this project
- Commercial use requires explicit permission from the copyright holder

Please review the [LICENSE](LICENSE) file before contributing.

## 🚀 Quick Start

1. Fork the repository
2. Clone your fork: `git clone https://github.com/masmovil/ClaudeUsageTracker.git`
3. Create a branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes
6. Commit: `git commit -m 'Add some feature'`
7. Push: `git push origin feature/your-feature-name`
8. Open a Pull Request

## 📝 Development Guidelines

### Code Style
- Follow Swift naming conventions
- Use clear, descriptive variable names
- Add comments for complex logic
- Keep functions small and focused

### Testing
Before submitting a PR:
1. Build the app: `./build.sh`
2. Test all features:
   - Menu bar display
   - Data loading
   - Language switching
   - Refresh functionality
3. Verify on a clean macOS installation if possible

### Commit Messages
- Use clear, descriptive commit messages
- Start with a verb (Add, Fix, Update, Remove, etc.)
- Examples:
  - `Add support for custom pricing`
  - `Fix loading state not updating menu bar`
  - `Update README with new features`

## 🐛 Bug Reports

We use GitHub issue templates to make bug reporting easier and more structured.

**To report a bug:**
1. Go to [Issues](../../issues/new/choose)
2. Select **"Bug Report"** template
3. Fill in all required sections:
   - Bug description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (macOS version, app version, etc.)
   - Screenshots if applicable

**The template will guide you through providing:**
- Detailed reproduction steps
- Your system configuration
- Whether you're using API or local mode
- Troubleshooting steps you've already tried
- Relevant logs from Console.app

## 💡 Feature Requests

We welcome feature requests! We have a dedicated template to help you submit comprehensive proposals.

**To request a feature:**
1. Go to [Issues](../../issues/new/choose)
2. Select **"Feature Request"** template
3. Describe:
   - The problem you're trying to solve
   - Your proposed solution
   - Alternative approaches you've considered
   - Your use case and how often you'd use it
   - Implementation ideas (if you have technical knowledge)

**Before submitting:**
- Search [existing issues](../../issues) to avoid duplicates
- Check if it's already planned in project roadmap
- Consider if it aligns with the project's purpose

## ❓ Questions

For general questions about using the app:
1. Check the [README](README.md) and [Installation Guide](INSTALL.md) first
2. Search [existing issues](../../issues) and [discussions](../../discussions)
3. If still unsure, use the **"Question"** issue template
4. For community discussions, prefer [GitHub Discussions](../../discussions)

## 🔍 Pull Request Process

We have a comprehensive Pull Request template to ensure quality contributions.

**Before creating a PR:**
1. Fork the repository and create your feature branch
2. Make your changes following our code style guidelines
3. Test thoroughly on macOS (see Testing section above)
4. Update documentation if needed (README, comments, etc.)
5. Ensure the app builds without errors: `./build.sh`

**When submitting a PR:**
1. Go to [Pull Requests](../../pulls)
2. Click "New Pull Request"
3. Our template will automatically load - **fill in all sections:**
   - Description and related issue number
   - Type of change (bug fix, feature, etc.)
   - Testing performed and results
   - Checklist items (code quality, functionality, documentation)
   - Screenshots (if applicable)
   - License compliance confirmation

**The PR template includes:**
- ✅ Code quality checklist
- ✅ Functionality verification steps
- ✅ Documentation requirements
- ✅ License compliance acknowledgment
- ✅ Testing checklist specific to this app

**After submission:**
1. Wait for automated checks to pass (if any)
2. Respond to review feedback promptly
3. Make requested changes in new commits
4. Request re-review once changes are made

**Review Process:**
- Maintainers will review your code for quality and functionality
- You may be asked to make changes
- Once approved, your PR will be merged
- Thank you for your contribution!

## 📧 Questions?

Open an issue with the `question` label.

Thank you for contributing! 🎉
