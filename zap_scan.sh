#!/bin/bash
 
# ZAP Security Scanning Script with Swagger Integration
 
echo "=== Starting ZAP Security Scan ==="
 
# Configuration
APP_URL="http://spring-boot-hello-world:8081"
ZAP_URL="http://localhost:8090"
OPENAPI_URL="$APP_URL/v3/api-docs"
REPORTS_DIR="./zap_reports"
 
mkdir -p "$REPORTS_DIR"

# Start ZAP daemon
echo "Starting ZAP daemon..."
zap.sh -daemon -host 0.0.0.0 -port 8090 -config api.disablekey=true &
ZAP_PID=$!
 
# Wait for ZAP to start
sleep 30
 
# Import OpenAPI specification
echo "Importing OpenAPI specification..."

curl -s -X GET "$ZAP_URL/JSON/openapi/action/importUrl/?url=$OPENAPI_URL"
sleep 5
 
# ---------------- Spider Scan ----------------
echo "Starting spider scan..."
SPIDER_ID=$(curl -s "$ZAP_URL/JSON/spider/action/scan/?url=$APP_URL/" | sed -E 's/.*"scan":"([0-9]+)".*/\1/')
echo "Spider scan ID: $SPIDER_ID"
 
while true; do
    STATUS=$(curl -s "$ZAP_URL/JSON/spider/view/status/?scanId=$SPIDER_ID" | sed -E 's/.*"status":"([0-9]+)".*/\1/')
    echo "Spider progress: $STATUS%"
    [ "$STATUS" == "100" ] && break
    sleep 5
done
 
# ---------------- Active Scan ----------------
echo "Starting active scan..."
SCAN_ID=$(curl -s "$ZAP_URL/JSON/ascan/action/scan/?url=$APP_URL/" | sed -E 's/.*"scan":"([0-9]+)".*/\1/')
echo "Active scan ID: $SCAN_ID"
 
while true; do
    STATUS=$(curl -s "$ZAP_URL/JSON/ascan/view/status/?scanId=$SCAN_ID" | sed -E 's/.*"status":"([0-9]+)".*/\1/')
    echo "Active scan progress: $STATUS%"
    [ "$STATUS" == "100" ] && break
    sleep 30
done
 
# ---------------- Reports ----------------
echo "Generating security reports..."
 
# HTML Report
curl -s "$ZAP_URL/OTHER/core/other/htmlreport/" > "$REPORTS_DIR/security-report.html"
 
# JSON Report
curl -s "$ZAP_URL/JSON/core/view/alerts/" > "$REPORTS_DIR/alerts.json"
 
# XML Report
curl -s "$ZAP_URL/XML/core/view/alerts/" > "$REPORTS_DIR/alerts.xml"
 
# ---------------- Summary ----------------
echo "=== SECURITY SCAN SUMMARY ===" > "$REPORTS_DIR/scan-summary.txt"
echo "Scan completed at: $(date)" >> "$REPORTS_DIR/scan-summary.txt"
echo "Application URL: $APP_URL" >> "$REPORTS_DIR/scan-summary.txt"
echo "OpenAPI Spec: $OPENAPI_URL" >> "$REPORTS_DIR/scan-summary.txt"
 
# Count alerts by risk level (using alertsSummary API for clean counts)
SUMMARY=$(curl -s "$ZAP_URL/JSON/core/view/alertsSummary/?baseurl=$APP_URL")
 
HIGH_ALERTS=$(echo "$SUMMARY" | sed -E 's/.*"High":"?([0-9]+)"?.*/\1/')
MEDIUM_ALERTS=$(echo "$SUMMARY" | sed -E 's/.*"Medium":"?([0-9]+)"?.*/\1/')
LOW_ALERTS=$(echo "$SUMMARY" | sed -E 's/.*"Low":"?([0-9]+)"?.*/\1/')
INFO_ALERTS=$(echo "$SUMMARY" | sed -E 's/.*"Informational":"?([0-9]+)"?.*/\1/')
 
echo "High Risk Alerts: $HIGH_ALERTS" >> "$REPORTS_DIR/scan-summary.txt"
echo "Medium Risk Alerts: $MEDIUM_ALERTS" >> "$REPORTS_DIR/scan-summary.txt"
echo "Low Risk Alerts: $LOW_ALERTS" >> "$REPORTS_DIR/scan-summary.txt"
echo "Informational Alerts: $INFO_ALERTS" >> "$REPORTS_DIR/scan-summary.txt"
 
echo "=== Scan completed successfully! ==="
echo "Reports available in: $REPORTS_DIR"
 
# Keep container running (optional, only needed in Docker)
tail -f /dev/null
 
 