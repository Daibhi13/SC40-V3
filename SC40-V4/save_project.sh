#!/bin/bash
# Script to manually save Xcode project
echo "Saving Xcode project..."
osascript -e 'tell application "Xcode" to save all documents'
echo "Project saved successfully!"
