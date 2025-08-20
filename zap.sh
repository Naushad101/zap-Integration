#!/bin/bash

TARGET_URL=$1
SCAN_TYPE=$2
REPORT_NAME="zap_report.html"

echo "Starting ZAP ${SCAN_TYPE} scan against ${TARGET_URL}"

if [ "${SCAN_TYPE}" == "passive" ]; then
  docker run --rm -v $(pwd):/zap/wrk -t ghcr.io/zaproxy/zaproxy:stable \
    zap-baseline.py -t "$TARGET_URL" -r "$REPORT_NAME"
elif [ "${SCAN_TYPE}" == "active" ]; then
  docker run --rm -v $(pwd):/zap/wrk -t ghcr.io/zaproxy/zaproxy:stable \
    zap-full-scan.py -t "$TARGET_URL" -r "$REPORT_NAME"
else
  echo "Invalid scan type: ${SCAN_TYPE}. Use 'active' or 'passive'."
  exit 1
fi

exit_code=$?
if [[ $exit_code -ne 0 ]]; then
  echo "ZAP scan found vulnerabilities. Check the report at $REPORT_NAME."
  exit 1
else
  echo "ZAP scan completed successfully."
fi
