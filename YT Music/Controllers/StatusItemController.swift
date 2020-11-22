//
//  StatusItemController.swift
//  CastSync
//
//  Created by Miles Hollingsworth on 4/22/18
//  Copyright © 2018 Miles Hollingsworth. All rights reserved.
//

import Cocoa
import OpenCastSwift
import SwiftyJSON

class StatusItemController: NSObject {
  let statusItem = NSStatusBar.system.statusItem(withLength: 36)
  
  let scanner = CastDeviceScanner()
  var clients = [String: CastClient]()
  
  override init() {
    super.init()
    
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(devicesChanged),
                                           name: CastDeviceScanner.deviceListDidChange,
                                           object: scanner)
    
    
    let menu = NSMenu()
    menu.delegate = self
    statusItem.menu = menu
    setMenus()
    statusItem.button?.title = ""
    statusItem.button?.image = NSImage(named: NSImage.Name("Cast"))
  }
  
  @objc func devicesChanged() {
    setMenus(devices: scanner.devices)
  }
  
  func setMenus(devices: [CastDevice] = []) {
    guard let menu = statusItem.menu else { return }
    
    if menu.items.count > 0 {
      menu.removeAllItems()
    }
    
    if devices.count > 0 {
      let items = devices.map { NSMenuItem(title: $0.name, action: #selector(handleSelection(item:)), keyEquivalent: "") }
      
      for item in items {
        item.target = self
        menu.addItem(item)
      }
    } else {
      let item = NSMenuItem(title: "Scanning", action: #selector(handleSelection(item:)), keyEquivalent: "")
      menu.addItem(item)
    }
  }
  
  @objc func handleSelection(item: NSMenuItem) {
    guard let index = statusItem.menu?.items.firstIndex(of: item) else { return }
    
    let device = scanner.devices[index]
    
    let client = CastClient(device: device)
    self.clients[device.id] = client
    client.delegate = self
    client.connect()
  }
  
  @objc func handleRefresh() {
    scanner.reset()
  }
}

extension StatusItemController: NSMenuDelegate {
  func menuWillOpen(_ menu: NSMenu) {
    scanner.startScanning()
  }
  
  func menuDidClose(_ menu: NSMenu) {
    scanner.stopScanning()
  }
}

extension StatusItemController: CastClientDelegate {
  func castClient(_ client: CastClient, didConnectTo device: CastDevice) {
    guard client.isConnected else { return }
    client.launch(appId: CastAppIdentifier.youTube) { result in
            switch result {
            case .success(let app):
                client.requestMediaStatus(for: app)

            case .failure(let error):
                print(error)
            }

    }
  }
    
  
  func castClient(_ client: CastClient, deviceStatusDidChange status: CastStatus) {
    guard status.apps.count > 0, client.connectedApp == nil else { return }

    client.setMuted(false)

    return client.join() { result in
      switch result {
      case .success(let app):
        let videoURL = URL(string: "https://www.youtube.com/watch?v=_f2NpgG7biw")!
        let posterURL = URL(string: "https://i.imgur.com/GPgh0AN.jpg")!

        // create a CastMedia object to hold media information
        let media = CastMedia(title: "Test Bars",
                                url: videoURL,
                                poster: posterURL,
                                contentType: "application/vnd.apple.mpegurl",
                                streamType: CastMediaStreamType.buffered,
                                autoplay: true,
                                currentTime: 0)

        // app is the instance of the app you got from the client after calling launch, or from the status callbacks
        client.load(media: media, with: app) { result in
                  switch result {
                  case .success(let status):
                    print(status)

                  case .failure(let error):
                    print(error)
                  }
            }

      case .failure(let error):
        print(error)
      }
    }
  }
  
  func castClient(_ client: CastClient, mediaStatusDidChange status: CastMediaStatus) {
    print(status.metadata as Any)
//    client.stopCurrentApp()
  }
  
  func castClient(_ client: CastClient, connectionTo device: CastDevice, didFailWith error: Error?) {
    print(error as Any)
    client.disconnect()
  }
}
