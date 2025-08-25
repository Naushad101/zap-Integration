
#!/bin/bash

STATUS_CODE=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8090)

if [ "$STATUS_CODE" -eq 200 ]; then
  echo "✅ ZAP is up and running (HTTP $STATUS_CODE)"
  exit 0
else
  echo "❌ ZAP is not ready (HTTP $STATUS_CODE)"
  exit 1
fi
