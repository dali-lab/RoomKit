// https://github.com/Quick/Quick

import Quick
import Nimble
import RoomKit

class RoomKitSpec: QuickSpec {
    override func spec() {
		describe("configuration") {
			it("configures and validates", closure: {
				waitUntil(timeout: 20, action: { (done) in
					let configD = ["serverURL": "https://roomkit.herokuapp.com", "userKey": "4ef9f9ac1ae8432439be02dc9ac6d84b8ae11ddd5af98015a5"]
					let configO = RoomKit.Config(dict: configD)
					expect(configO).notTo(beNil())
					if let config = configO {
						RoomKit.configure(config: config, callback: { (error) in
							if let error = error { print(error) }
							expect(error).to(beNil())
							done()
						})
					}else{
						done()
					}
				})
			})
		}
    }
}
