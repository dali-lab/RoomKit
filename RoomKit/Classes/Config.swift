//
//  Config.swift
//  Nimble
//
//  Created by John Kotz on 2/2/18.
//

import Foundation

extension RoomKit {
	public class Config {
		internal let server: String
		internal let serverURL: URL
		internal let adminKey: String?
		internal let userKey: String
		
		public init?(dict: Dictionary<String, Any>) {
			guard let server = dict["serverURL"] as? String, let userKey = dict["userKey"] as? String, let url = URL(string: server) else {
				return nil
			}
			
			self.server = server
			self.userKey = userKey
			self.adminKey = dict["adminKey"] as? String
			self.serverURL = url
		}
		
		internal func validate(callback: @escaping (_ valid: Bool, _ reason: String?) -> Void) {
			let url = URL(string: "\(server)/authenticated")!
			var request = URLRequest(url: url)
			request.addValue(userKey, forHTTPHeaderField: "authorization")
			
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				let code = (response as? HTTPURLResponse)?.statusCode ?? 500
				if code != 200 {
					if let data = data {
						callback(false, code == 401 ? "unauthorized" : (String.init(data: data, encoding: .utf8)?.lowercased() ?? "unknown"))
					}else {
						callback(false, "unknown")
					}
				}else{
					callback(true, nil)
				}
			}.resume()
		}
	}
}
