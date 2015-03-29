//
//  RecordedAudio.swift
//  Pitch Perfect
//
//  Created by Christopher Johnson on 3/16/15.
//  Copyright (c) 2015 Christopher Johnson. All rights reserved.
//

import Foundation

class RecordedAudio: NSObject {
    
    var filePathURL:NSURL!
    var title:String!
    
    override init() {
        var path = NSFileManager()
        filePathURL = NSURL(fileURLWithPath: path.currentDirectoryPath)
        title = "sofiNeedsALadder.mp3"
    }
    
    init(pathURL:NSURL, title:String!) {
        self.filePathURL = pathURL
        self.title = title
    }
}