#!/bin/bash

# ── CONFIGURATION ──────────────────────────────────────────────────
MODEL="gemma3:4b"
IMAGE_PATH="/tmp/frame.jpg"
LOG_FILE="ollama_log.txt"
INTERVAL=60   # seconds between captures
PROMPT="Describe this image. Make it shorter."

# ── LOGGING HELPERS ────────────────────────────────────────────────
log_response() {
    local response="$1"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    {
        echo "========================================"
        echo "Timestamp: $timestamp"
        echo "----------------------------------------"
        echo "$response"
        echo "========================================"
        echo ""
    } >> "$LOG_FILE"
}

log_error() {
    local error_type="$1"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    {
        echo "========================================"
        echo "Timestamp: $timestamp"
        echo "----------------------------------------"
        case "$error_type" in
            "no_frame")
                echo "ERROR: Camera missed a frame — no image captured"
                ;;
            "ollama_fail")
                echo "ERROR: Ollama failed to respond — model may be offline"
                ;;
            "empty_response")
                echo "ERROR: Ollama returned an empty response"
                ;;
            *)
                echo "ERROR: Unknown error occurred"
                ;;
        esac
        echo "========================================"
        echo ""
    } >> "$LOG_FILE"
}

# ── CAPTURE + ANALYZE ──────────────────────────────────────────────
run_and_log() {
    # Step 1: Capture image from webcam
    imagesnap -q "$IMAGE_PATH" 2>/dev/null
    if [ ! -f "$IMAGE_PATH" ]; then
        log_error "no_frame"
        return
    fi

    # Step 2: Convert image to base64
    BASE64_IMAGE=$(base64 < "$IMAGE_PATH" | tr -d '\n')

    # Step 3: Build JSON payload and call Ollama API
    JSON_BODY=$(printf '{"model":"%s","prompt":"%s","images":["%s"],"stream":false}' \
        "$MODEL" "$PROMPT" "$BASE64_IMAGE")

    RESPONSE=$(curl -s -X POST http://localhost:11434/api/generate \
        -H "Content-Type: application/json" \
        -d "$JSON_BODY")

    # Step 4: Check curl succeeded
    if [ $? -ne 0 ]; then
        log_error "ollama_fail"
        return
    fi

    # Step 5: Parse the response field out of the JSON
    PARSED=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['response'])")

    if [ -z "$PARSED" ]; then
        log_error "empty_response"
        return
    fi

    # Step 6: Log the result
    log_response "$PARSED"
    echo "$(date '+%H:%M:%S') — Frame analyzed and logged."
}

# ── MAIN LOOP ──────────────────────────────────────────────────────
echo "Security camera started. Logging to: $LOG_FILE"
echo "Interval: ${INTERVAL}s | Model: $MODEL"
echo "Press Ctrl+C to stop."
echo ""

while true; do
    run_and_log
    sleep "$INTERVAL"
done
