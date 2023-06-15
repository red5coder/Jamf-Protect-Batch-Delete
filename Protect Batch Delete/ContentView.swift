//
//  ContentView.swift
//  Protect Batch Delete
//
//  Created by Richard Mallion on 21/02/2023.
//

import SwiftUI
import os.log


struct ContentView: View {
    
    @State private var protectURL = ""
    @State private var clientID = ""
    @State private var password = ""
    
    @State private var savePassword = false

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    
    @State private var selectedDays: Int = 0
    
    @State private var foundComputers = [Item]()
    
    @State private var selection: Item.ID?
    @State private var sortOrder = [KeyPathComparator(\Item.hostName)]
    @State private var searchText = ""
    
    @State private var deleteButtonDisabled = true
    @State private var fetchButtonDisabled = true

    @State private var showingConfirmation = false

    
    @State private var importedFromCVS = false

    var searchResults: [Item] {
        if searchText.isEmpty {
            return foundComputers
        } else {
            return foundComputers.filter { $0.serial.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var selectedComputerCount:Int {
        var count = 0
        foundComputers.forEach {
            if $0.delete {
                count = count + 1
            }
        }
        return count
    }
    
    var confirmationMessage: String {
        if selectedComputerCount < 2 {
            return "Do you wish to delete \(selectedComputerCount) computer?"
        }
        return "Do you wish to delete \(selectedComputerCount) computers?"
    }


    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            HStack(alignment: .center){
                
                VStack(alignment: .trailing, spacing: 12.0) {
                    Text("Protect URL:")
                    Text("Client ID:")
                    Text("Password:")
                }
                
                VStack(alignment: .leading, spacing: 7.0) {
                    TextField("https://your.protect.jamfcloud.com" , text: $protectURL)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: protectURL) { newValue in
                            let defaults = UserDefaults.standard
                            defaults.set(protectURL , forKey: "protectURL")
                            updateFetchButton()
                        }

                    TextField("Your Jamf Protect Client ID" , text: $clientID)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: clientID) { newValue in
                            let defaults = UserDefaults.standard
                            defaults.set(clientID , forKey: "clientID")
                            updateFetchButton()
                        }

                    SecureField("Your password" , text: $password)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: password) { newValue in
                            if savePassword {
                                DispatchQueue.global(qos: .background).async {
                                    Keychain().save(service: "co.uk.mallion.jamfprotect-batch-delete", account: "password", data: password)
                                }
                            }
                            updateFetchButton()
                        }

                }
            }
            .padding()
            .alert(isPresented: self.$showAlert,
                   content: {
                self.showCustomAlert()
            })
            
            Toggle(isOn: $savePassword) {
                Text("Save Password")
            }
            .toggleStyle(CheckboxToggleStyle())
            .offset(x: 102 , y: -10)
            .onChange(of: savePassword) { newValue in
                let defaults = UserDefaults.standard
                defaults.set(savePassword, forKey: "savePassword")
                if savePassword {
                    DispatchQueue.global(qos: .background).async {
                        Keychain().save(service: "co.uk.mallion.jamfprotect-batch-delete", account: "password", data: password)
                    }
                } else {
                    DispatchQueue.global(qos: .background).async {
                        Keychain().save(service: "co.uk.mallion.jamfprotect-batch-delete", account: "password", data: "")
                    }
                }
            }
            
            Table(searchResults, selection: $selection , sortOrder: $sortOrder) {
                
                TableColumn("Delete") { item in
                    Toggle("", isOn: Binding<Bool>(
                       get: {
                          return item.delete
                       },
                       set: {
                           if let index = foundComputers.firstIndex(where: { $0.id == item.id }) {
                               foundComputers[index].delete = $0
                           }
                           var disableDelete = true
                           foundComputers.forEach {
                               if $0.delete {
                                   disableDelete = false
                               }
                               deleteButtonDisabled = disableDelete
                           }
                       }
                    ))

                }
                .width(45)

                TableColumn("Hostname", value: \.hostName)
                TableColumn("Serial", value: \.serial)
                TableColumn("Checkin", value: \.formatedCheckin)
                TableColumn("Status", value: \.status)
            }
            .padding()
            .onChange(of: sortOrder) { newOrder in
                foundComputers.sort(using: newOrder)
            }
            .searchable(text: $searchText, prompt: "Serial Number")
                
                HStack(alignment: .center) {
                    Spacer()

                    Picker("Not Checked-in", selection: $selectedDays) {
                        Text("7 days").tag(0)
                        Text("14 days").tag(1)
                        Text("30 days").tag(2)
                        Text("90 days").tag(3)
                        Text("180 days").tag(4)
                        Text("360 days").tag(5)
                        Text("0 days").tag(6)
                    }
                    .frame(width: 200)
                    
                    Button("Clear") {
                        Task {
                            foundComputers = [Item]()
                        }
                    }
                    .padding()

                    Button("Import CSV") {
                        Task {
                           importCSV()
                        }
                    }

                    Button("Fetch") {
                        Task {
                            await fetchComputersFromProtect()
                        }
                    }
                    .padding([ .leading ])
                    .disabled(fetchButtonDisabled)

                    Button("Delete Selected") {
                        Task {
                            showingConfirmation = true
                        }
                    }
                    .padding()
                    .disabled(deleteButtonDisabled)
                    .confirmationDialog("Delete Computers", isPresented: $showingConfirmation) {
                        Button("Cancel", role: .cancel ) {

                        }
                        Button("Delete All", role: .destructive) {
                            Task {
                                if importedFromCVS {
                                    await deleteCSVComputers()
                                } else {
                                    await deleteSelectedComputers()
                                }
                            }
                        }

                    } message: {
                        Text(confirmationMessage)
                    }

                }

        }
        .onAppear {
            let defaults = UserDefaults.standard
            clientID = defaults.string(forKey: "clientID") ?? ""
            protectURL = defaults.string(forKey: "protectURL") ?? ""
            savePassword = defaults.bool(forKey: "savePassword" )
            if savePassword  {
                let credentialsArray = Keychain().retrieve(service: "co.uk.mallion.jamfprotect-batch-delete")
                if credentialsArray.count == 2 {
                    password = credentialsArray[1]
                }
            }
            updateFetchButton()
        }


    }
    
    
    func importCSV() {
        Logger.protect.info("Import a csv file selected.")
        importedFromCVS = true
        deleteButtonDisabled = true
        foundComputers = [Item]()

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Select CSV"
        panel.message = "Please select a csv file of serial numbers."
        panel.allowedContentTypes = [ .commaSeparatedText ]
        if panel.runModal() == .OK {
            if let csvPath = panel.url {
                do {
                    let content = try String(contentsOfFile: csvPath.path)
                    Logger.protect.info("\(csvPath.path, privacy: .public) was selected.")
                    let parsedCSV: [String] = content.components(separatedBy: "\n").filter{ !$0.isEmpty }
                    for serial in parsedCSV {
                        let item = Item(delete: true, status: "csv", uuid: "", checkin: "", hostName: "", serial: serial.uppercased().replacingOccurrences(of: "\n", with: "") )
                        foundComputers.append(item)
                    }
                    Logger.protect.info("\(foundComputers.count, privacy: .public) computers imported from csv file.")
                    if foundComputers.count > 0 {
                        deleteButtonDisabled = false
                    }
                } catch {
                    Logger.protect.error("Could Not read CSV File.")
                    print("Could Not read CSV File")
                }
            }
        }
    }
    
    
    func updateFetchButton() {
        if protectURL.validURL && !clientID.isEmpty && !password.isEmpty  {
            fetchButtonDisabled = false
        } else {
            fetchButtonDisabled = true
        }
    }

    
    func showCustomAlert() -> Alert {
        return Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
                )
    }
    
    
    func deleteCSVComputers() async {
        Logger.protect.info("Delete computers was selected.")
        let jamfProtect = JamfProtectAPI()
        let (authToken, httpRespoonse) = await jamfProtect.getToken(protectURL: protectURL, clientID: clientID, password: password)
        guard let authToken else {
            alertMessage = "Could not authenticate. Please check the url and authentication details"
            alertTitle = "Authentication Error"
            showAlert = true
            return
        }
        Logger.protect.info("Sucessfully authenticated to Protect.")
        var showError = false
        
        var message = "All \(selectedComputerCount) computers where deleted."
        if selectedComputerCount < 2 {
           message = "The computer was deleted."
        }
        
        for (index, computer) in foundComputers.enumerated() {
            if computer.delete {
                let (computerResult, computerResponse) = await jamfProtect.listComputerBySerial(protectURL: "https://eduservices1.protect.jamfcloud.com" , access_token: authToken.access_token, serial: computer.serial)
                guard let computerResult = computerResult else { continue }
                if let computerResponse = computerResponse , computerResponse == 200 , computerResult.data.listComputers.items.count > 0 {
                    Logger.protect.info("Deleted computer \(computer.serial, privacy: .public).")
                    foundComputers[index].checkin = computerResult.data.listComputers.items[0].checkin
                    foundComputers[index].uuid = computerResult.data.listComputers.items[0].uuid
                    foundComputers[index].hostName = computerResult.data.listComputers.items[0].hostName
                    foundComputers[index].status = "Found"
                    if let responseCode = await jamfProtect.deleteComputer(protectURL: protectURL , access_token: authToken.access_token, uuid: foundComputers[index].uuid) {
                        if responseCode != 200 {
                            Logger.protect.error("Could not delete computer \(computer.serial, privacy: .public), error \(responseCode).")
                            foundComputers[index].status = "Error \(responseCode)"
                            showError = true
                        } else {
                            Logger.protect.info("Computer \(computer.serial, privacy: .public) was deleted.")
                            foundComputers[index].status = "Deleted"
                        }
                    }
                } else {
                    Logger.protect.error("Could not find computer \(computer.serial, privacy: .public).")
                    showError = true
                    foundComputers[index].status = "Error \(computerResponse)"
                }
            }
        }
        
        
        if showError {
            //Deletion was unsuccessful
            alertMessage = "Could not Delete one or more computers"
            alertTitle = "Error"
            showAlert = true
        } else {
            //Deletion was successful
            alertMessage = message
            alertTitle = "Successful Deletion"
            showAlert = true
            deleteButtonDisabled = true
        }


        
    }

    func deleteSelectedComputers() async {
        Logger.protect.info("Delete computers was selected.")
        let jamfProtect = JamfProtectAPI()
        let (authToken, httpRespoonse) = await jamfProtect.getToken(protectURL: protectURL, clientID: clientID, password: password)
        guard let authToken else {
            alertMessage = "Could not authenticate. Please check the url and authentication details"
            alertTitle = "Authentication Error"
            showAlert = true
            return
        }
        Logger.protect.info("Sucessfully authenticated to Protect.")
        var showError = false
        
        var message = "All \(selectedComputerCount) computers where deleted."
        if selectedComputerCount < 2 {
           message = "The computer was deleted."
        }

        
        for (index, computer) in foundComputers.enumerated() {
            if computer.delete {
                if let responseCode = await jamfProtect.deleteComputer(protectURL: protectURL , access_token: authToken.access_token, uuid: computer.uuid) {
                    if responseCode != 200 {
                        Logger.protect.error("Could not delete computer \(computer.serial, privacy: .public), error \(responseCode).")
                        foundComputers[index].status = "Error \(responseCode)"
                        showError = true
                    } else {
                        Logger.protect.info("Computer \(computer.serial, privacy: .public) was deleted.")
                        foundComputers[index].status = "Deleted"
                    }
                }
            }
        }
        
        
        if showError {
            //Deletion was unsuccessful
            alertMessage = "Could not Delete one or more computers"
            alertTitle = "Error"
            showAlert = true
        } else {
            //Deletion was successful
            alertMessage = message
            alertTitle = "Successful Deletion"
            showAlert = true
            deleteButtonDisabled = true
        }
    }
    
    
    func dateString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        let formatedDate = formatter.string(from: date)
        return formatedDate
    }
    
    
    
    func fetchComputersFromProtect() async {
        Logger.protect.info("Fetch computers from Protect was selected.")
        importedFromCVS = false
        deleteButtonDisabled = true

        foundComputers = [Item]()

        let jamfProtect = JamfProtectAPI()
        
        let (authToken, httpRespoonse) = await jamfProtect.getToken(protectURL: protectURL, clientID: clientID, password: password)
        
        guard let authToken else {
            alertMessage = "Could not authenticate. Please check the url and authentication details"
            alertTitle = "Authentication Error"
            showAlert = true
            return
        }

        Logger.protect.info("Sucessfully authenticated to Protect.")

        var days = 7
        switch selectedDays{
            case 0:
                days = 7
            case 1:
                days = 14
            case 2:
                days = 30
            case 3:
                days = 90
            case 4:
                days = 180
            case 5:
                days = 360
            case 6:
                days = 0
            default:
                days = 7
        }
        
        Logger.protect.info("\(days, privacy: .public) days was selected.")
        let past = Calendar.current.date(byAdding: .day, value: -(days), to: Date())!
        let dateformat = ISO8601DateFormatter()
        dateformat.formatOptions.insert(.withFractionalSeconds)
        let searchDate = dateformat.string(from: past)
        let (listComputers, httpRespoonse2) = await jamfProtect.listComputers(protectURL: protectURL, access_token: authToken.access_token, searchDate: searchDate)
         if let items = listComputers?.data.listComputers.items {
             foundComputers = items
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



extension String {
    var validURL: Bool {
        get {
            let regEx = "^((http|https)://)[-a-zA-Z0-9@:%._\\+~#?&//=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%._\\+~#?&//=]*)$"
            let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regEx])
            return predicate.evaluate(with: self)
        }
    }
}

