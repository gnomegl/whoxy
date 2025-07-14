#!/bin/bash

show_usage() {
  echo "Usage: whoxy [options] value"
  echo ""
  echo "Search options (one required):"
  echo "  --history  Domain history lookup"
  echo "  --name     Search by domain owner's name"
  echo "  --email    Search by email address"
  echo "  --company  Search by company/organization name"
  echo "  --keyword  Search by keyword at start of domain name"
  echo ""
  echo "Additional options:"
  echo "  --page N   Get page N of results (default: 1)"
  echo "  --mode M   Result mode: normal (default), mini, micro, domains"
  echo "             (domains mode only works with --keyword)"
}

if [ $# -lt 2 ]; then
  show_usage
  exit 1
fi


API_KEY="${WHOXY_API_KEY:-YOUR_API_KEY}"

if [ "$API_KEY" = "YOUR_API_KEY" ] || [ -z "$API_KEY" ]; then
  echo "Error: Export the API key as WHOXY_API_KEY."
  exit 1
fi


PAGE=1
MODE="normal"
FORMAT="json"
SEARCH_TYPE=""
SEARCH_VALUE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --history)
      SEARCH_TYPE="history"
      SEARCH_VALUE="$2"
      shift 2
      ;;
    --name|--email|--company|--keyword)
      if [ -n "$SEARCH_TYPE" ]; then
        echo "Error: Only one search type can be specified"
        exit 1
      fi
      SEARCH_TYPE="${1#--}"
      SEARCH_VALUE="$2"
      shift 2
      ;;
    --page)
      PAGE="$2"
      shift 2
      ;;
    --mode)
      MODE="$2"
      shift 2
      ;;
    *)
      echo "Error: Unknown option $1"
      show_usage
      exit 1
    ;;
      esac
    done

    if [ -z "$SEARCH_TYPE" ] || [ -z "$SEARCH_VALUE" ]; then
      echo "Error: Must specify a search type (--history, --name, --email, --company, or --keyword) and value"
      show_usage
      exit 1
    fi

    if [ "$MODE" = "domains" ] && [ "$SEARCH_TYPE" != "keyword" ]; then
      echo "Error: domains mode can only be used with --keyword search"
      exit 1
    fi

    if [ "$SEARCH_TYPE" = "history" ]; then
      # domain history lookup
      curl -s "https://api.whoxy.com/?key=${API_KEY}&history=${SEARCH_VALUE}" | \
      jq '
      [
        .whois_records[] | 
        {
          query_time: .query_time, 
          contacts: {registrant_contact: .registrant_contact, administrative_contact: .administrative_contact},
        }
      ]'
    else
      # reverse whois lookup
      URL="https://api.whoxy.com/?key=${API_KEY}&reverse=whois&${SEARCH_TYPE}=${SEARCH_VALUE}"
      
      if [ "$PAGE" != "1" ]; then
        URL="${URL}&page=${PAGE}"
      fi
      if [ "$MODE" != "normal" ]; then
        URL="${URL}&mode=${MODE}"
      fi

    URL=$(echo "$URL" | sed 's/ /+/g')

    curl -s "$URL" | jq '.'
    fi
