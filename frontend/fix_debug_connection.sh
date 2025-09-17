#!/bin/bash

echo "🔧 Fixing Flutter debug connection issues..."

# Kill existing ADB processes
echo "📱 Stopping ADB processes..."
adb kill-server

# Wait a moment
sleep 2

# Start ADB again
echo "🔄 Starting ADB server..."
adb start-server

# Check connected devices
echo "📱 Checking connected devices..."
adb devices

# Clear Flutter cache
echo "🧹 Clearing Flutter cache..."
flutter clean

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

echo "✅ Debug connection fix attempt completed!"
echo "Now try running: flutter run"
