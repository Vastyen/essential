#!/bin/bash

# Script to generate app icon using Swift
# This will create all required icon sizes for macOS

echo "🎨 Generating Essential app icon..."

# Create output directory
OUTPUT_DIR="IconOutput"
mkdir -p "$OUTPUT_DIR"

# Compile and run the Swift script
swiftc -o /tmp/generate_icon Essential/GenerateIcon.swift 2>/dev/null

if [ $? -eq 0 ]; then
    /tmp/generate_icon
    echo ""
    echo "✅ Icons generated successfully!"
    echo "📁 Check the $OUTPUT_DIR folder"
else
    echo "⚠️  Could not compile Swift script. Using alternative method..."
    echo "💡 You can run this in Xcode by creating a temporary SwiftUI preview"
fi

