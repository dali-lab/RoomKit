//
//  Config.swift
//  Nimble
//
//  Created by John Kotz on 2/2/18.
//

import Foundation

extension RoomKit {
    /**
     A configuration for the RoomKit library
     
     To get some keys, go to https://roomkit.herokuapp.com/register and fill out the form.
        This will generate the keys you will need to configure RoomKit
     */
	public class Config {
		internal let server: String
		internal let serverURL: URL
		internal let adminKey: String?
		internal let userKey: String
        
        /**
         Create a config with a user and admin key, using the default server
         
         - parameter userKey: The user key. Used for accessing the maps in the project
         - parameter adminKey: The admin key. Used for modifying or creating maps in the project
         */
        public init(userKey: String, adminKey: String?) {
            self.server = "https://roomkit.herokuapp.com"
            self.serverURL = URL(string: self.server)!
            self.userKey = userKey
            self.adminKey = adminKey
        }
		
        /**
         Create a config with a custom dictionary. This allows you to put a plist straight into the
            config, keeping things like keys and server url in a seperate git-ignorable file.
         
         - parameter dict: Dictionary contianing 'serverURL', 'userKey', and 'adminKey'
         */
		public init?(dict: Dictionary<String, Any>) {
			guard let server = dict["serverURL"] as? String, let userKey = dict["userKey"] as? String, let url = URL(string: server) else {
				return nil
			}
			
			self.server = server
			self.userKey = userKey
			self.adminKey = dict["adminKey"] as? String
			self.serverURL = url
		}
		
        /**
         Validate the config
         */
		internal func validate(callback: @escaping (_ valid: Bool, _ reason: String?) -> Void) {
			let url = URL(string: "\(self.server)/authenticated")!
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
