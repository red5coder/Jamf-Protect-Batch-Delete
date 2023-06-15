# Jamf-Protect-Batch-Delete
Please NOTE the app is currently in beta.

The "Jamf Protect Batch Delete" utility is a macOS app that allows you to batch delete computer records from a Jamf Protect tenant.

### Requirements

- A Mac running macOS Venture (13.0)
- A Jamf Protect Tenant
- A Jamf Protect API client needs to be created with the following permissions. 
  - Read and Write for Computers
  - Read and Write for Alerts

### Usage
The app will require the credentials to access your Jamf Protect Tenant. This includes:
  - Your Jamf Protect URL
  - The Client ID for the API Client you created
  - The password for the API client you created
  
You can fetch a list of computers from your Jamf Protect Ternant based on a last check-in period.

You can also import a list of serial numbers from a csv file. The file just needs a single column of serial numbers.

i.e  
ZRFN72C5GI  
ZRFN63C5GJ  
ZRFN91C5GH

You can then select which computers to delete.

The app does log to Unified Logging. You can view the logs like this:

`log stream --predicate 'subsystem == "co.uk.mallion.jamf-protect-batch-delete"' --level info`


<img width="1014" alt="Screenshot2" src="https://user-images.githubusercontent.com/29920386/221022124-c77f8982-2321-4ed9-a019-b788e430929e.png">
