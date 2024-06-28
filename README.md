###
Detect dangling DNS

### Description
This script helps in identifying dangling DNS records by performing various scans on a list of domains. It takes input from a file called domains.txt, scans each domain for various parameters, and exports the results in JSON and CSV formats.

### Usage

1. Create a File with Domains

    * Create a file called domains.txt.

    * List all the domains you want to scan in this file. You can use tools like dnsdumpster, amass, subdomain finder, etc., to populate this file.

2. Run the Script

    *Execute the script using the following command:
    ```
    bash audit-domain.sh
    ```

### Scan Details

The script performs various scans on each domain and outputs the following details:

```
{
  "subdomains": "www.example.com",
  "dns_resolution": "success",
  "curl": "success",
  "dig": "success",
  "header": "200",
  "wget": "okay",
  "ping": "success"
}
```

### Scans Performed

* DNS Resolution: Checks if the domain resolves successfully.
* Curl: Tests if the domain can be accessed using the curl command.
* Dig: Performs a DNS lookup using the dig command.
* Header: Retrieves the HTTP status code of the domain.
* Wget: Tests if the domain can be accessed using the wget command.
* Ping: Checks if the domain responds to ping requests.

###
Output

The results of the scans are exported in both JSON and CSV file formats for easy analysis and reporting.

### Example domains.txt
```
example.com
test.com
mywebsite.org
```

### Notes

Ensure you have the necessary permissions to run the script and perform network scans.
Make sure to review and validate the domains listed in domains.txt to avoid scanning unintended targets.

By using this tool, you can effectively identify and address dangling DNS records, enhancing the security and reliability of your domain infrastructure.
