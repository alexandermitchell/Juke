//
//  Playlist.swift
//  Juker
//
//  Created by Alex Mitchell on 2017-06-13.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit

class Playlist: NSObject {
    
    var name: String
    var trackRequestURL: String
    var playlistID: String
    var ownerID: String
    var image: String
    
    
    init(jsonDictionary: [String:AnyObject]) {
        
        let owner = jsonDictionary["owner"] as! [String : AnyObject]
        let images = jsonDictionary["images"] as! [[String : AnyObject]]
        
        self.name = jsonDictionary["name"] as! String
        self.trackRequestURL = jsonDictionary["href"] as! String
        self.playlistID = jsonDictionary["id"] as! String
        self.ownerID = owner["id"] as! String
        self.image = images.first?["url"] as! String

    }

}
