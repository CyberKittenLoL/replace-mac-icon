# Replace / update mac app icon

## Important note

This only allow to replace app download from the internet

## To use

### 1.Add app to appIcon.json

```json
{
  "config": { # optional
    "custom_icon_dir": "$HOME/.custom-icons" # Default path
  },
  "app": [
    {
      "icon_path": "chrome",        # Your custom icon name in dir, must be icns
      "app_path": "Google Chrome",  # App name before .app
      "icon_name": "app",           # Optional if not given it will auto find
      "enable": true                # Optional but default false i.e. wont change
    }
  ]
}
```

### 2. Then run replace_icons.sh

## Debug
Log filename: `output.log`

To stream the output, `tail -f output.log`
