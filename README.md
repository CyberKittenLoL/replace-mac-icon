# Replace / update mac app icon

## Important note

This only allow to replace internet downloaded app

## To use

Add app to appIcon.json

```json
{
  "config": {                       # optional
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

Then run replace_icons.sh