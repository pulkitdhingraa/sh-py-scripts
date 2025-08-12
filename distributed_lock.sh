#!/bin/bash

LOCK_DIR="/tmp/distributed_lock/lock"
PID_FILE="$LOCK_DIR/pid"

acquire_lock() {
    if mkdir "$LOCK_DIR" 2>/dev/null; then
        echo $$ > "$PID_FILE"
        echo "[INFO] Lock acquired by PID $$"
        trap 'release_lock' EXIT SIGTERM SIGINT
        return 0
    else
        if [ -f "$PID_FILE" ]; then
            local lock_pid
            lock_pid=$(cat "$PID_FILE")
            #if the lock_pid cannot be killed that means stale process
            if ! kill -0 "$lock_pid" 2>/dev/null; then
                echo "[WARN] Stale lock detected (PID : $lock_pid). Cleaning up..."
                rm -rf "$LOCK_DIR"
                acquire_lock
                return $?
            fi
            echo "[ERROR] Lock is held by active PID $lock_pid"
        else
            echo "[ERROR] Lock dir exists without PID file"
        fi
        return 1
    fi
}

release_lock() {
    if [ -d "$LOCK_DIR" ]; then
        rm -rf "$LOCK_DIR"
        echo "[INFO] Lock released by PID $$"
}

protected_code() {
    echo "[INFO] Running protected code section for PID $$"
    sleep 5
    echo "[INFO] Protected section complete for PID $$"
}

if acquire_lock; then
    protected_code
    release_lock
else
    echo "[INFO] Could not acquire lock. Exiting"
    exit 1
fi