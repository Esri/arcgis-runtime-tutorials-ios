//
//  Router.swift
//  MyFirstMapApp
//
//  Created by Jeff Kereakoglow on 4/12/16.
//  Copyright © 2016 Esri. All rights reserved.
//

import Foundation

/// Usage: `Router.Oceans.URL`
enum Router {
  static let baseURLString = "http://services.arcgisonline.com/ArcGIS/rest/services/"

  case LightGray
  case Ocean
  case NatGeo
  case Topo
  case Imagery

  var URL: NSURL {
    let path: String = {
      switch self {
      case .LightGray:
        return "Canvas/World_Light_Gray_Base"
      case .Ocean:
        return "Ocean_Basemap/MapServer"
      case .NatGeo:
        return "NatGeo_World_Map/MapServer"
      case .Topo:
        return "World_Topo_Map/MapServer"
      case .Imagery:
        return "World_Imagery/MapServer"
      }
    }()

    let baseURL = NSURL(string: Router.baseURLString)!
    return baseURL.URLByAppendingPathComponent(path)
  }
}
