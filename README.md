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
You can then select which computers to delete.

<img width="1014" alt="screen" src="https://user-images.githubusercontent.com/29920386/220759837-3be5d840-9d16-41d9-8f22-da153a09d6ca.png">
