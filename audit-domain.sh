#!/usr/bin/env bash


# Read domains from domains.txt into an array
domains=()
while IFS= read -r line; do
    domains+=("$line")
done < "domains.txt"

protocol=""

valid_status_codes=(
    200
    201
    202
    301
    302
    303
    304
    305
    306
    307
    308
    400
    401
    402
    403
    409
    500
    501
    502
    503
    504
    505
)

# Function to check if a site responds to HTTP or HTTPS
check_protocol() {
    local site="$1"
    local http_response
    local https_response

    # Check HTTP
    http_response=$(curl -s -o /dev/null -w "%{http_code}" "http://$site")
    if [ "$http_response" == "200" ]; then
        protocol="http"
        return
    fi

    # Check HTTPS
    https_response=$(curl -s -o /dev/null -w "%{http_code}" "https://$site")
    if [ "$https_response" == "200" ]; then
        protocol="https"
    else
        final_url=$(curl -s -w "%{url_effective}" -o /dev/null -L "http://$site")
        if [[ "$final_url" =~ ^https:// ]]; then
            protocol="https"
            return
        fi
    fi

     # Check if there's a redirection to HTTPS
    final_url=$(curl -s -w "%{url_effective}" -o /dev/null -L "http://$site")
    if [[ "$final_url" =~ ^https:// ]]; then
        protocol="https"
        return
    fi
}

# Function to check DNS resolution
check_dns() {
    local result=""
    if nslookup "$1" >/dev/null; then
        result="success"
    else
        result="failed"
    fi
    printf "\"dns_resolution\": \"%s\"" "$result" | tee -a "$output_file"
}

# Function to check reachability with cURL
check_curl() {
    local result=""
    local http_code
    http_code=$(curl -Ls -o /dev/null -I -w "%{http_code}" "$2://$1")
    local valid=false
    for code in "${valid_status_codes[@]}"; do
        if [ "$code" -eq "$http_code" ]; then
            valid=true
            break
        fi
    done
    if [ "$valid" = true ]; then
        result="success"
    else
        result="failed"
    fi
    printf ", \"curl\": \"%s\"" "$result" | tee -a "$output_file"
}

# Function to check with dns records presence using dig
check_dig() {
    local result=""
    if dig +short "$1" >/dev/null 2>&1; then
        result="success"
    else
        result="failed"
    fi
    printf ", \"dig\": \"%s\"" "$result" | tee -a "$output_file"
}

# Function to check reachability using ping
check_ping() {
    local result=""
    if ping -c 4 "$1" >/dev/null 2>&1; then
        result="success"
    else
        result="failed"
    fi
    printf ", \"ping\": \"%s\"" "$result" | tee -a "$output_file"
}

# Function to check header information i.e status code
check_header() {
    local result
    local header
    header=$(curl -I "$2://$1" 2>/dev/null | head -n 1)
    if header=$(curl -I "$2://$1" 2>/dev/null | head -n 1); then
        result=$(echo "$header" | awk '{print $2}')
    else
        result="not_okay"
    fi
    printf ", \"header\": \"%s\"" "$result" | tee -a "$output_file"
}

# Function to check reachability with wget
check_wget() {
    local result=""
    local final_url
    final_url=$(curl -s -w "%{url_effective}" -o /dev/null -L "http://$1")
    if wget -q --spider "$final_url" -T 5 -t 1 2>/dev/null; then
        result="okay"
    else
        result="not_okay"
    fi
    printf ", \"wget\": \"%s\"" "$result" | tee -a "$output_file"
}

# Loop through the list of domains and perform checks
output_file="output.json"
echo "[" | tee "$output_file"
for ((i=0; i<${#domains[@]}; i++)); do
    printf "{ \"subdomains\": \"%s\", " "${domains[i]}" | tee -a "$output_file"
    check_protocol "${domains[i]}"
    check_dns "${domains[i]}"
    check_curl "${domains[i]}" "$protocol"
    check_dig "${domains[i]}"
    check_header "${domains[i]}" "$protocol"
    check_wget "${domains[i]}" "$protocol"
    check_ping "${domains[i]}"
    if [ $i -eq $((${#domains[@]} - 1)) ]; then
        echo "  }" | tee -a "$output_file"
    else
        echo "  }," | tee -a "$output_file"

    fi
done
echo "]" | tee -a "$output_file"

# convert json to csv format
jq -r '.[] | [.subdomains, .dns_resolution, .curl, .dig, .header, .wget, .ping] | @csv' output.json > output.csv