#!/bin/bash
start_time=$(date +%s)
json_file="appIcon.json"
log_file="output.log"
custom_icon_dir="$HOME/.custom-icons" # Default custom icon directory

# Run main or test
run_test=false
# Test variables
test_app_name="Steam"
test_custom_icon="steamIcon"
# test_app_icon_name="app.icns"
test_without_modified_icon=false 

# Log level
# 0 - No log
# 1 - Error
# 2 - Info
# 3 - Debug
log_level=3

log_check_size() {
  local log_size=$(wc -c < "$log_file")
  if [[ "$log_size" -gt 1000000 ]]; then
    echo "[init] Log file size exceeded 1MB. Clearing log file."
    echo "" > "$log_file"
  fi
}

echo_log() {
  if [[ "$#" -lt 2 ]]; then
    echo "Usage: echo_log <message> <level>"
    return
  fi
  if [[ "$log_level" -eq 0 ]]; then
    return
  fi
  local message="$1"
  local level="$2"
  local log_level_str="NO LEVEL SET"
  if [[ "$level" -eq 3 ]]; then
    log_level_str="debug"
  elif [[ "$level" -eq 2 ]]; then
    log_level_str="info"
  elif [[ "$level" -eq 1 ]]; then
    log_level_str=": ERROR :"
  elif [[ "$level" -eq 0 ]]; then
    log_level_str="!: FATAL :!"
  elif [[ "$level" -eq -1 ]]; then
    echo "$message" > "$log_file"
    return
  else
    level=0
  fi

  if [[ "$level" -le "$log_level" ]]; then
    echo "[$log_level_str] $message" > "$log_file"
  fi
}

select_choice() {
  local choices=("$@")
  if [ "${#choices[@]}" -eq 1 ]; then
    echo "Only one choice available: ${choices[0]}"
    return 0
  else
    echo "Multiple choices available:"
    local index=1
    for choice in "${choices[@]}"; do
      echo "$index. $choice"
      index=$((index + 1))
    done

    # Prompt user for input
    echo "Please enter your choice (index):"
    read user_input
    echo "You selected: $user_input"
    if [[ "$user_input" =~ ^[0-9]+$ ]]; then
      if [ "$user_input" -ge 1 ] && [ "$user_input" -le "${#choices[@]}" ]; then
        echo "Selected: ${choices[$((user_input-1))]}"
        return $((user_input-1))
      else
        echo "Invalid choice. Please try again."
        select_choice "${choices[@]}"
      result=$?
      fi
    else
      echo "Invalid input. Please enter a number."
      select_choice "${choices[@]}"
      result=$?
    fi
    result=$?
    
    return $result
  fi
}

full_app_path () {
  local app_name="$1"
  if [[ "$app_name" != *.app ]]; then
    app_name="$app_name.app"
  fi
  echo "/Applications/$app_name"
}

full_custom_icon_path () {
  local custom_icon="$1"
  if [[ "$custom_icon" != *.icns ]]; then
    if [[ "$custom_icon" == *.* ]]; then
      echo_log "Error custom icon: Invalid icon file extension for $custom_icon. Only .icns files are allowed." 1
      echo ""
      return
    else
      custom_icon="$custom_icon.icns"
    fi
  fi

  echo "$custom_icon_dir/$custom_icon"
}

full_app_icon_path () {
  local app_name="$1"
  local icon_name="$2"
  local echo_output="${3:-true}"
  if [[ "$icon_name" != *.icns ]]; then
    if [[ "$icon_name" == *.* ]]; then
      echo_log "Error app icon: Invalid icon file extension for $icon_name. Only .icns files are allowed." 1
      echo ""
      return
    else
      icon_name="$icon_name.icns"
    fi
  fi
  echo "/Applications/$app_name/Contents/Resources/$icon_name"
}

test_path() {
  local path_to_check="$1"
  local description="$2"
  local echo_output="${3:-true}"

  if ! [ -e "$path_to_check" ]; then
    if [[ -n "$echo_output" ]]; then
      echo_log "$description not found: $path_to_check" 1
    fi
    return 1
  fi
  if [[ -n "$echo_output" ]]; then
    echo_log "$description found: $path_to_check" 3
  fi
  return 0
}

choose_icon() {
  echo_log "No default icon found. Prompting user to choose an icon file." 3

  # Find all .icns files and store them in an array
  IFS=$'\n' read -d '' -r -a files < <(find "$1/Contents/Resources" -iname "*.icns" -maxdepth 8)

  # Check if any files were found
  if [[ ${#files[@]} -eq 0 ]]; then
    echo_log "No .icns files found in the specified directory." 1
    return 1
  fi

  # Extract the filenames from the full paths
  filenames=()
  for file in "${files[@]}"; do
    filenames+=("$(basename "$file")")
  done

  # Display the filenames with indices
  # PS3="Enter the number of your choice or 'q' to quit: "
  # select filename in "${filenames[@]}"; do
  #   if [[ -n "$filename" ]]; then
  #     selected_file="${files[$((REPLY-1))]}"
  #     echo_log "Selected icon: $selected_file" 3
  #     echo "$selected_file"
  #   elif [[ "$REPLY" == "q" ]]; then
  #     echo_log "Quitting selection." 2
  #     break
  #   else
  #     echo_log "Invalid selection. Please try again."
  #   fi
  # done
  select_choice "${filenames[@]}" > /dev/null
  echo_log "Selected icon: ${files[$?]}" 3
  echo "${files[$?]}"
}

find_icon() {
  local app_path="$1"
  local app_name="$2"
  local app_icon_path

  echo_log "Finding APP Icon for app: $app_name" 3

  # Check for app.icns
  app_icon_path=$(find "$app_path/Contents/Resources" -iname "app.icns" -maxdepth 8)
  if [[ -n "$app_icon_path" ]]; then
    echo_log "Icon found: $app_icon_path" 3
    echo "$app_icon_path"
    return
  fi
  echo_log "No app.icns found." 3


  # Check for appIcon.icns
  app_icon_path=$(find "$app_path/Contents/Resources" -iname "appIcon.icns" -maxdepth 8)
  if [[ -n "$app_icon_path" ]]; then
    echo_log "Icon found: $app_icon_path" 3
    echo "$app_icon_path"
    return
  fi
  echo_log "No appIcon.icns found." 3

  # Check for exact match *appname*.icns
  app_icon_path=$(find "$app_path/Contents/Resources" -iname "$app_name.icns" -maxdepth 8)
  if [[ -n "$app_icon_path" ]]; then
    echo_log "Icon found: $app_icon_path" 3
    echo "$app_icon_path"
    return
  fi
  echo_log "No $app_name.icns found." 3

  # Check for wildcard match *appname*.icns
  app_icon_path=$(find "$app_path/Contents/Resources" -iname "*$app_name*.icns" -maxdepth 8)
  if [[ -n "$app_icon_path" ]]; then
    echo_log "Icon found: $app_icon_path" 3
    echo "$app_icon_path"
    return
  fi
  echo_log "No *$app_name*.icns found." 3

  # If no exact match, search for each word individually in reverse order
  local quite_loop=false
  IFS=' ' read -r -a words <<< "$app_name"
  for (( i=${#words[@]}-1; i>=0; i-- )); do
    app_icon_path=$(find "$app_path/Contents/Resources" -iname "*${words[$i]}*.icns" -maxdepth 8)
    if [[ -n "$app_icon_path" ]]; then
      echo_log "Icon found for confirm: $app_icon_path" 3
      read -p "Enter your choice (y/n/q for quit and choose from list): " choice
      if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        echo "$app_icon_path"
        return
      elif [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        quite_loop=true
        break
      fi
    fi
  done
  if [[ "$quite_loop" = true ]]; then
    echo_log "Quit searching for icon." 2
  else
    echo_log "No $app_name partly found." 3
  fi

  # If no icons are found, prompt user to choose
  echo_log "No icon found. Prompting user to choose an icon." 3
  local chosen_icon=$(choose_icon "$app_path")
  if [[ -z "$chosen_icon" ]]; then
    echo_log "No icon found for 1 $app_name" 1
    echo ""
    return
  fi
  if [[ -f "$chosen_icon" ]]; then
    echo_log "Icon found / chosen: $chosen_icon" 2
    echo "$chosen_icon"
    return
  fi

  echo_log "No icon found for $app_name" 1
  echo ""
}

backup_icon() {
  local app_icon_path="$1"
  local app_name="$2"
  local backup_path="${app_icon_path}.backup"
  if [[ -f "$backup_path" ]]; then
    echo_log "Backup icon already exists: $backup_path" 3
    return 0
  fi
  echo_log "Backing up current icon: $app_icon_path to $backup_path" 3
  if ! cp "$app_icon_path" "$backup_path" > /dev/null 2>&1; then
    echo_log "Try sudo to backup icon" 3
    echo "Try sudo to backup icon"
    if ! sudo cp "$app_icon_path" "$backup_path" > /dev/null; then
      echo_log "Failed to backup current icon for $app_name." 1
      return 1
    fi
  fi
  return 0
}

any_changed=0
replace_icon() {
  local custom_icon="$1"
  local app_name="$2"
  local icon_name="$3"

  echo_log "-  -  Start replace process  -  -" 3
  echo_log "App:  $app_name" 3 
  echo_log "Icon: $custom_icon" 3

  local app_path=$(full_app_path "$app_name")
  local new_icon_path=$(full_custom_icon_path "$custom_icon")

  test_path "$app_path" "App"
  if [ $? -eq 1 ] ; then
    return 1
  fi
  
  test_path "$new_icon_path" "Icon"
  if [ $? -eq 1 ]; then
    return 1
  fi

  if [[ -z "$icon_name" ]]; then
    icon_name=$(basename "$new_icon_path")
  fi
  test_path "$app_path/Contents/Resources" "App Resources" false
  if [ $? -eq 1 ]; then
    return 1
  fi

  test_path "$(full_app_icon_path "$app_name" "$icon_name")" "App Icon" false
  if [ $? -eq 0 ]; then
    echo_log "App Icon found" 3
    app_icon_path=$(full_app_icon_path "$app_name" "$icon_name")
  else
    echo_log "App Icon not found, try auto finding" 2
    app_icon_path=$(find_icon "$app_path" "$app_name")
    echo_log "Auto find icon result: $app_icon_path" 3
  fi
  if [[ -z "$app_icon_path" ]]; then
    echo_log "Failed to find icon for $app_name: No valid icon path found." 1
    return 1
  fi
  if [[ "$test_without_modified_icon" = true ]]; then
    echo_log "Test without modified icon" 0
    return 1
  fi
  
  if ! backup_icon "$app_icon_path" "$app_name"; then
    echo_log "Failed to backup icon for $app_name." 1
    return 1
  fi

  echo_log "Replacing icon with new icon: $new_icon_path" 3
  if ! cp "$new_icon_path" "$app_icon_path" > /dev/null 2>&1; then
    echo_log "Try sudo to replace icon" 3
    echo "Try sudo to replace icon"
    if ! sudo cp "$new_icon_path" "$app_icon_path" > /dev/null; then
      echo_log "Failed to replace icon for $app_name." 1
      return 1
    fi
  fi

  if ! touch "$app_path" > /dev/null 2>&1; then
    echo_log "Try sudo to touch app" 3
    echo "Try sudo to touch app"
    if ! sudo touch "$app_path" > /dev/null; then
      echo_log "Failed to touch app for $app_name." 1
      return 1
    fi
  fi
  echo_log "$app_name updated icon successfully." 2

  any_changed=$((any_changed + 1))
  echo_log "any_changed = $any_changed" 3
  return 0
}

restart_finder() {
  sudo killall Finder
  echo_log "Finder Restarted" 2
}

main(){
  while read -r app; do
    icon_path=$(echo "$app" | jq -r '.icon_path')
    app_path=$(echo "$app" | jq -r '.app_path')
    icon_name=$(echo "$app" | jq -r '.icon_name')
    enable=$(echo "$app" | jq -r '.enable')
    if [[ "$enable" != true ]]; then
      echo_log "Skipping $app_path" 2
      continue
    fi
    replace_icon "$icon_path" "$app_path" "$icon_name"
  done < <(jq -c '.apps[]' "$json_file")

  end_time=$(date +%s)
  echo "Execution time: $((end_time - start_time)) seconds."
  echo_log "any_changed = $any_changed" 3
  if [[ $any_changed -eq 0 ]]; then
    echo_log "No icons were updated." 2
    return
  else
    echo_log "All $any_changed icons updated successfully." 2
    restart_finder
  fi
}

test() {
  replace_icon "$test_custom_icon" "$test_app_name" "$test_app_icon_name"
  end_time=$(date +%s)
  echo_log "Execution time: $((end_time - start_time)) seconds." 3

  if [[ "$any_changed" -eq 0 ]]; then
    echo_log "No icons were updated." 2
  else
    echo_log "All icons updated successfully." 2
    read -p "Do you want to restart Finder? (y/n): " choice
    case "$choice" in 
      y|Y ) restart_finder;;
      * ) echo_log "Finder restart skipped." 2;
    esac
  fi
}

init () {
  log_check_size
  if [[ "$run_test" = true ]]; then
    echo_log "Running in test mode." 2
  fi
  if [[ -f "$json_file" ]]; then
    echo_log "JSON file found: $json_file" 3
  else
    echo_log "Error: JSON file not found." 1
    echo "No JSON file found: $json_file"
    echo ""
    exit 1
  fi
  local cid=$(jq -r '.config.custom_icon_dir' "$json_file")
  if [[ -d "$cid" ]]; then
    custom_icon_dir="$cid"
    echo_log "Custom icon directory: $custom_icon_dir" 3
  else
    echo_log "Custom icon directory not found or not exists. Using default directory." 2
  fi
}

echo_log "" -1
echo_log "Start of running" -1

init

if [[ "$run_test" = true ]]; then
  test
else
  main
fi

echo_log "End of running" -1
echo_log "" -1
# End of script

