# Screenshots Guide

For a more attractive README, consider adding these screenshots to your repository.

## Recommended Screenshots

### 1. Menu Bar Icon
**Filename**: `screenshots/menubar.png`
- Show the menu bar with the app icon: 💰 $177.83
- Capture just the top-right corner of the screen
- Make sure it's clear and readable

### 2. Main Panel - By Month Tab
**Filename**: `screenshots/by-month.png`
- Open the app panel
- Make sure "By Month" tab is selected
- Show 2-3 months of data
- Capture the entire panel with clean data

### 3. Main Panel - By Project Tab
**Filename**: `screenshots/by-project.png`
- Switch to "By Project" tab
- Show 3-4 projects
- Capture the entire panel

### 4. Language Selector
**Filename**: `screenshots/language-selector.png`
- Click on the flag icon to show the dropdown
- Capture the menu showing both language options

## How to Capture Screenshots

1. **Press** `Cmd + Shift + 4`
2. **Press** `Space` to capture a specific window
3. **Click** on the window you want to capture

Or use `Cmd + Shift + 4` and drag to select a specific area.

## Adding Screenshots to README

Once you have the screenshots:

1. Create a `screenshots/` directory in the repo
2. Add your images there
3. Update README.md with:

```markdown
## 📸 Screenshots

### Menu Bar
![Menu Bar](screenshots/menubar.png)

### Monthly View
![By Month](screenshots/by-month.png)

### Project View
![By Project](screenshots/by-project.png)

### Language Selector
![Language Selection](screenshots/language-selector.png)
```

4. Update `.gitignore` to track screenshots:
```
# Screenshots (tracked)
!screenshots/
!screenshots/*.png
```

## Tips for Great Screenshots

- Use a clean desktop background
- Close unnecessary apps
- Use default macOS theme (or specify which one)
- Ensure good contrast and readability
- Use realistic data (not all zeros)
- Capture at actual size (no zoom)
