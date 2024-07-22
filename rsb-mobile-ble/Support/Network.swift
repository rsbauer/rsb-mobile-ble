//
//  Network.swift
//  rsb-mobile-ble
//
//  Created by Astro on 7/2/24.
//

import Foundation

class Network {
    func POST(url urlStr: String, json: [String: Any]) {
        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        guard let url = URL(string: urlStr) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }

            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }

        task.resume()
    }
}
