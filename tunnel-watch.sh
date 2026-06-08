#!/bin/bash
# Auto-maintain localhost.run tunnel for shuibei-gold page
# Checks every 2 minutes if tunnel is alive, restarts if dead

HTTP_PORT=8899
TUNNEL_LOG=/tmp/tunnel.log

# Ensure HTTP server is running
if ! pgrep -f "python3 -m http.server $HTTP_PORT" > /dev/null; then
  cd /home/hermes/shuibei-gold-pwa && nohup python3 -m http.server $HTTP_PORT &
fi

# Get current URL from log
CURRENT_URL=$(grep "lhr.life tunneled" "$TUNNEL_LOG" 2>/dev/null | tail -1 | grep -oP 'https://[a-z0-9]+\.lhr\.life' | tail -1)

if [ -n "$CURRENT_URL" ]; then
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$CURRENT_URL" 2>/dev/null)
  if [ "$STATUS" = "200" ]; then
    echo "OK: $CURRENT_URL ($STATUS)"
    exit 0
  fi
fi

# Tunnel is dead, restart it
echo "Tunnel dead, restarting..."
kill $(pgrep -f "ssh.*localhost.run" 2>/dev/null) 2>/dev/null
sleep 2
cd /home/hermes/shuibei-gold-pwa && nohup ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -R 80:localhost:$HTTP_PORT nokey@localhost.run 2>&1 | tee "$TUNNEL_LOG" &
sleep 5
NEW_URL=$(grep "lhr.life tunneled" "$TUNNEL_LOG" 2>/dev/null | tail -1 | grep -oP 'https://[a-z0-9]+\.lhr\.life' | tail -1)
echo "NEW: $NEW_URL"
