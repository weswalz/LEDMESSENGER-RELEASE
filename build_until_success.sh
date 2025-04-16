#!/bin/bash

echo "🔄 Starting build loop until success..."

while true; do
    echo "🛠️  Attempting build..."
    
    # Run xcodebuild and capture output
    # Add CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION=YES to fix entitlements error
    BUILD_OUTPUT=$(xcodebuild -project LEDMESSENGER.xcodeproj -scheme LEDMESSENGER_macOS CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION=YES 2>&1)
    BUILD_RESULT=$?
    
    # Check if build succeeded
    if [ $BUILD_RESULT -eq 0 ]; then
        echo "✅ Build succeeded!"
        exit 0
    else
        # Count the number of errors
        ERROR_COUNT=$(echo "$BUILD_OUTPUT" | grep -c "error:")
        echo "❌ Build failed with $ERROR_COUNT errors. Retrying..."
        echo "$BUILD_OUTPUT" | grep "error:" | head -5
        
        # Wait a moment before retrying
        sleep 2
    fi
done