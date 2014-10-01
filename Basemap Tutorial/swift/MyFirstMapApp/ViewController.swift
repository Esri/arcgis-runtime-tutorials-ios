/*
Copyright 2014 Esri

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import UIKit
import ArcGIS

let kBasemapLayerName = "Basemap Tiled Layer"

class ViewController: UIViewController, AGSMapViewLayerDelegate {
                            
    @IBOutlet weak var mapView: AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Add a basemap tiled layer
        let url = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer")
        let tiledLayer = AGSTiledMapServiceLayer(URL: url)
        self.mapView.addMapLayer(tiledLayer, withName: kBasemapLayerName)
        
        //Set the map view's layer delegate
        self.mapView.layerDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //MARK: map view layer delegate methods
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        //do something now that the map is loaded
        //for example, show the current location on the map
        mapView.locationDisplay.startDataSource()
    }
    
    //MARK: actions
    
    @IBAction func basemapChanged(sender: UISegmentedControl) {
        
        var basemapURL:NSURL
        
        switch sender.selectedSegmentIndex {
            case 0:  //gray
                basemapURL = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer")
            case 1:  //oceans
                basemapURL = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/Ocean_Basemap/MapServer")
            case 2:  //nat geo
                basemapURL = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/NatGeo_World_Map/MapServer")
            case 3:  //topo
                basemapURL = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer")
            default:  //sat
                basemapURL = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer")
        }
        
        //remove the existing basemap layer
        self.mapView.removeMapLayerWithName(kBasemapLayerName)
        
        //add new Layer
        let newBasemapLayer = AGSTiledMapServiceLayer(URL: basemapURL)
        self.mapView.insertMapLayer(newBasemapLayer, withName: kBasemapLayerName, atIndex: 0);
    }
}

