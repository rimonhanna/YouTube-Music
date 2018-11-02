//
//  YTMusicScriptCommand.swift
//  YT Music
//
//  Created by Rimon Hanna on 02/11/2018.
//  Copyright © 2018 Cocoon Development Ltd. All rights reserved.
//

import Foundation
import Cocoa

@objc class YTMusicScriptCommand : NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        // Retrieve command
        let command = self.commandDescription.commandName
        
        // Retrieve command param
        //let parameter = self.directParameter
        
        let viewController = NSApplication.shared.windows.first?.contentViewController as? ViewController

        
        switch (command){
        case "playpause":
            viewController?.playPause()
            break;
            
        case "next track":
            viewController?.nextTrack()
            break;
            
        case "previous track":
            viewController?.previousTrack()
            break;
        
        default:
            break;
        }
        
        return nil;
    }
}
