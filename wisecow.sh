#!/bin/bash

# Wisecow Application - A fortune cookie web server
SRVPORT=${SRVPORT:-4499}

# Function to generate fortune with cowsay
generate_fortune() {
    if command -v fortune >/dev/null 2>&1 && command -v cowsay >/dev/null 2>&1; then
        fortune | cowsay
    else
        echo "Moo! Fortune and cowsay are required but not installed."
    fi
}

# Function to send HTTP response
send_response() {
    local status_code="$1"
    local content_type="$2"
    local body="$3"
    
    echo -e "HTTP/1.1 $status_code\r"
    echo -e "Content-Type: $content_type\r"
    echo -e "Connection: close\r"
    echo -e "Content-Length: ${#body}\r"
    echo -e "\r"
    echo -e "$body"
}

# Function to handle a single request
handle_request() {
    read -r method path version
    
    # Read and discard headers
    while read -r line; do
        [[ "$line" == $'\r' ]] && break
    done
    
    if [[ "$method" == "GET" && "$path" == "/" ]]; then
        local fortune_output
        fortune_output=$(generate_fortune)
        local html_body="<!DOCTYPE html>
<html>
<head>
    <title>Wisecow - Fortune Teller</title>
    <style>
        body { font-family: monospace; margin: 40px; background: #f0f8ff; }
        .container { max-width: 800px; margin: 0 auto; text-align: center; }
        pre { background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .refresh { margin-top: 20px; }
        a { color: #0066cc; text-decoration: none; font-weight: bold; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class='container'>
        <h1>🐄 Welcome to Wisecow! 🐄</h1>
        <pre>$fortune_output</pre>
        <div class='refresh'>
            <a href='/'>🎲 Get Another Fortune!</a>
        </div>
        <p><small>Powered by fortune and cowsay</small></p>
    </div>
</body>
</html>"
        send_response "200 OK" "text/html" "$html_body"
    else
        local error_body="<!DOCTYPE html><html><body><h1>404 - Not Found</h1><p><a href='/'>Go Home</a></p></body></html>"
        send_response "404 Not Found" "text/html" "$error_body"
    fi
}

echo "Starting Wisecow server on port $SRVPORT..."
echo "Visit http://localhost:$SRVPORT to see the magic! 🎭"

# Start server using socat for better reliability
while true; do
    socat TCP4-LISTEN:$SRVPORT,reuseaddr,fork EXEC:"$0 handle_single_request" 2>/dev/null
    sleep 1
done