//
//  JamfProtectAPI.swift
//  Protect Batch Delete
//
//  Created by Richard Mallion on 21/02/2023.
//

import Foundation

struct JamfProtectAPI {

    func getToken(protectURL: String , clientID: String, password: String) async  -> (JamfAuth?,Int?) {
        guard var jamfAuthEndpoint = URLComponents(string: protectURL) else {
            return (nil, nil)
        }
        
        jamfAuthEndpoint.path="/token"
        
        guard let url = jamfAuthEndpoint.url else {
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
            return (nil, nil)
        }
        
        let httpResponse = response as? HTTPURLResponse

        do {
            let protectToken = try JSONDecoder().decode(JamfAuth.self, from: data)
            return (protectToken, httpResponse?.statusCode)
        } catch _ {
            return (nil, httpResponse?.statusCode)
        }
    }
    
    
    func listComputers(protectURL: String, access_token: String, searchDate: String) async -> (ComputerResults?,Int?) {
        guard var jamfAuthEndpoint = URLComponents(string: protectURL) else {
            return (nil, nil)
        }
        jamfAuthEndpoint.path="/graphql"
        
        guard let url = jamfAuthEndpoint.url else {
            return (nil, nil)
        }
        
        var authRequest = URLRequest(url: url)
        authRequest.httpMethod = "POST"
        authRequest.setValue("\(access_token)", forHTTPHeaderField: "Authorization")

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
            authRequest.httpBody = jsonData
        }
        
        guard let (data, response) = try? await URLSession.shared.data(for: authRequest)
        else {
            return (nil, nil)
        }
        let httpResponse = response as? HTTPURLResponse

        do {
            let computerList = try JSONDecoder().decode(ComputerResults.self, from: data)
            return  (computerList, httpResponse?.statusCode)
        } catch  {
            print(error.localizedDescription)
            return (nil, httpResponse?.statusCode)
        }
    }
    
    
    
    func deleteComputers(protectURL: String, access_token: String, uuid: String) async -> Int? {
        guard var jamfAuthEndpoint = URLComponents(string: protectURL) else {
            return nil
        }
        jamfAuthEndpoint.path="/graphql"
        
        guard let url = jamfAuthEndpoint.url else {
            return nil
        }
        
        var authRequest = URLRequest(url: url)
        authRequest.httpMethod = "POST"
        authRequest.setValue("\(access_token)", forHTTPHeaderField: "Authorization")

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
            authRequest.httpBody = jsonData
        }
        
        guard let (data, response) = try? await URLSession.shared.data(for: authRequest)
        else {
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
    let id = UUID()
    var delete = false
    let uuid, checkin : String
    let hostName, serial: String
    
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
