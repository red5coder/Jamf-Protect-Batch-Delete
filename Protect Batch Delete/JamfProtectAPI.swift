//
//  JamfProtectAPI.swift
//  Protect Batch Delete
//
//  Created by Richard Mallion on 21/02/2023.
//

import Foundation
import os.log

struct JamfProtectAPI {

    func getToken(protectURL: String , clientID: String, password: String) async  -> (JamfAuth?,Int?) {
        Logger.protect.info("Fetching authentication token.")
        guard var jamfAuthEndpoint = URLComponents(string: protectURL) else {
            Logger.protect.error("Protect URL seems invalid.")
            return (nil, nil)
        }
        
        jamfAuthEndpoint.path="/token"
        
        guard let url = jamfAuthEndpoint.url else {
            Logger.protect.error("Protect URL seems invalid.")
            return (nil, nil)
        }

        var authRequest = URLRequest(url: url)
        authRequest.httpMethod = "POST"
        
        let json: [String: Any] = ["client_id": clientID,
                                   "password": password]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        if let jsonData = jsonData {
            authRequest.httpBody = jsonData
        }
        
        guard let (data, response) = try? await URLSession.shared.data(for: authRequest)
        else {
            Logger.protect.error("Could not initiate connection to \(url, privacy: .public).")
            return (nil, nil)
        }
        
        let httpResponse = response as? HTTPURLResponse

        do {
            let protectToken = try JSONDecoder().decode(JamfAuth.self, from: data)
            Logger.protect.info("Authentication token decoded.")
            return (protectToken, httpResponse?.statusCode)
        } catch _ {
            Logger.protect.error("Could not decode authentication token.")
            return (nil, httpResponse?.statusCode)
        }
    }
    
    func listComputerBySerial(protectURL: String, access_token: String, serial: String) async -> (ComputerResults?,Int?) {
        Logger.protect.info("Fetching details for \(serial, privacy: .public) from Protect.")
        guard var jamfAuthEndpoint = URLComponents(string: protectURL) else {
            Logger.protect.error("Protect URL seems invalid.")
            return (nil, nil)
        }
        jamfAuthEndpoint.path="/graphql"
        
        guard let url = jamfAuthEndpoint.url else {
            Logger.protect.error("Protect URL seems invalid.")
            return (nil, nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(access_token)", forHTTPHeaderField: "Authorization")

        let listComputerQuery = """
query listComputers {
    listComputers(
        input: {
            filter: {
                serial: {
                    equals: "\(serial.uppercased())"
                }
            },
        }
    ) {
        items {
            hostName
            serial
            checkin
            uuid
        }
        pageInfo {
            next
        }
    }
}
"""
        
        let json: [String: Any] = ["query": listComputerQuery ]

        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        if let jsonData = jsonData {
            request.httpBody = jsonData
        }
        
        guard let (data, response) = try? await URLSession.shared.data(for: request)
        else {
            Logger.protect.error("Could not initiate connection to \(url, privacy: .public).")
            return (nil, nil)
        }
        let httpResponse = response as? HTTPURLResponse

        do {
            let computerList = try JSONDecoder().decode(ComputerResults.self, from: data)
            Logger.protect.info("Successfully decoded computer details from Protect.")
            return  (computerList, httpResponse?.statusCode)
        } catch  {
            Logger.protect.error("Could not decode data from Protect.")
            print(error.localizedDescription)
            return  (nil, httpResponse?.statusCode)
        }
    }

    
    
    func listComputers(protectURL: String, access_token: String, searchDate: String) async -> (ComputerResults?,Int?) {
        Logger.protect.info("Fetching details for computers not checked in for \(searchDate, privacy: .public) from Protect.")
        guard var jamfAuthEndpoint = URLComponents(string: protectURL) else {
            Logger.protect.error("Protect URL seems invalid.")
            return (nil, nil)
        }
        jamfAuthEndpoint.path="/graphql"
        
        guard let url = jamfAuthEndpoint.url else {
            Logger.protect.error("Protect URL seems invalid.")
            return (nil, nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(access_token)", forHTTPHeaderField: "Authorization")

        let listComputerQuery = """
query listComputers {
    listComputers(
        input: {
            filter: {
                checkin: {
                    lessThan: "\(searchDate)"
                }
            },
        }
    ) {
        items {
            hostName
            serial
            checkin
            uuid
        }
        pageInfo {
            next
        }
    }
}
"""
        
        let json: [String: Any] = ["query": listComputerQuery ]

        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        if let jsonData = jsonData {
            request.httpBody = jsonData
        }
        
        guard let (data, response) = try? await URLSession.shared.data(for: request)
        else {
            Logger.protect.error("Could not initiate connection to \(url, privacy: .public).")
            return (nil, nil)
        }
        let httpResponse = response as? HTTPURLResponse

        do {
            let computerList = try JSONDecoder().decode(ComputerResults.self, from: data)
            Logger.protect.info("Successfully decoded computer details from Protect.")
            Logger.protect.info("\(computerList.data.listComputers.items.count, privacy: .public) computers found.")
            return  (computerList, httpResponse?.statusCode)
        } catch  {
            Logger.protect.error("Could not decode data from Protect.")
            print(error.localizedDescription)
            return (nil, httpResponse?.statusCode)
        }
    }
    
    
    
    func deleteComputer(protectURL: String, access_token: String, uuid: String) async -> Int? {
        Logger.protect.info("Deleting computer \(uuid, privacy: .public) from Protect.")
        guard var jamfAuthEndpoint = URLComponents(string: protectURL) else {
            Logger.protect.error("Protect URL seems invalid.")
            return nil
        }
        jamfAuthEndpoint.path="/graphql"
        
        guard let url = jamfAuthEndpoint.url else {
            Logger.protect.error("Protect URL seems invalid.")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(access_token)", forHTTPHeaderField: "Authorization")

        let deleteComputerQuery = """
mutation deleteComputer {
    deleteComputer(
        uuid: "\(uuid)"
    ) {
        hostName
      }
    }
"""
        
        let json: [String: Any] = ["query": deleteComputerQuery ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        if let jsonData = jsonData {
            request.httpBody = jsonData
        }
        
        guard let (data, response) = try? await URLSession.shared.data(for: request)
        else {
            Logger.protect.error("Could not initiate connection to \(url, privacy: .public).")
            return nil
        }

        let httpResponse = response as? HTTPURLResponse
        return httpResponse?.statusCode
    }
    
    
}

// MARK: - Jamf Protect Auth Model
struct JamfAuth: Decodable {
    let access_token: String
    let expires_in: Int
    let token_type: String
}




// MARK: - ComputerResults
struct ComputerResults: Decodable {
    let data: DataClass
}

// MARK: - DataClass
struct DataClass: Decodable{
    let listComputers: ListComputers
}

// MARK: - ListComputers
struct ListComputers: Decodable {
    let items: [Item]
    let pageInfo: PageInfo
}

// MARK: - Item
struct Item: Decodable, Identifiable {
    var id = UUID()
    var delete = false
    var status = "Found"
    var uuid, checkin : String
    var hostName, serial: String
    
    var formatedCheckin: String {
        let components = self.checkin.components(separatedBy: ".")
        guard components.count > 1 else { return self.checkin }
        var formatedDate = components[0]
        formatedDate = formatedDate.replacingOccurrences(of: "T", with: " ")
        return formatedDate
    }

    enum CodingKeys: String, CodingKey {
        case hostName
        case serial
        case checkin
        case uuid
    }

}

// MARK: - PageInfo
struct PageInfo: Decodable {
    let next: String?
}
