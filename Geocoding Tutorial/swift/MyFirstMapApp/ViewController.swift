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

class ViewController: UIViewController, UISearchBarDelegate, AGSGeoViewTouchDelegate {
                            
    @IBOutlet weak var mapView: AGSMapView!
    var graphicLayer:AGSGraphicsOverlay!
    var locator:AGSLocatorTask!
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Initialize map with Light Gray Canvas basemap
        self.mapView.map = AGSMap(basemapType: .lightGrayCanvas, latitude: 0, longitude: 0, levelOfDetail: 0)
        
        //Start the location display
        self.mapView.locationDisplay.start(completion: nil)
        
        self.mapView.touchDelegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: search bar delegate methods
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //Hide the keyboard
        searchBar.resignFirstResponder()
        
        if self.graphicLayer == nil {
            //Add a graphics layer to the map. This layer will hold geocoding results
            self.graphicLayer = AGSGraphicsOverlay()
            self.mapView.graphicsOverlays.add(self.graphicLayer)
            
            //Assign a simple renderer to the layer to display results as pushpins
            let pushpin = AGSPictureMarkerSymbol(image: UIImage(named: "BluePushpin.png")!)
            pushpin.offsetX = 9
            pushpin.offsetY = 16
            pushpin.leaderOffsetX = -9
            pushpin.leaderOffsetY = 11
            let renderer = AGSSimpleRenderer(symbol: pushpin)
            self.graphicLayer.renderer = renderer
        }
        else {
            //Clear out previous results if we already have a graphics layer
            self.graphicLayer.graphics.removeAllObjects()
        }
        
        
        if self.locator == nil {
            //Create the AGSLocator pointing to the geocode service on ArcGIS Online
            //Set the delegate so that we are informed through AGSLocatorDelegate methods
            let url = URL(string: "http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer")
            self.locator = AGSLocatorTask(url: url!)
        }

        //Set the parameters
        let params = AGSGeocodeParameters()
        params.outputSpatialReference = self.mapView.spatialReference
        params.resultAttributeNames = ["*"]

        //Kick off the geocoding operation
        //This will invoke the geocode service on a background thread
        self.locator.geocode(withSearchText: searchBar.text!, parameters: params, completion: {
            (results,error) in
            
            if let results = results, results.count > 0{
                for result in results {
                    self.graphicLayer.graphics.add(AGSGraphic(geometry: result.displayLocation!, symbol: nil, attributes:result.attributes))
                }
                
                self.mapView.setViewpointGeometry(self.graphicLayer.extent, padding:30, completion:nil)
                
            }else if let error = error {
                let alert = UIAlertController(title: "No results found", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            }
            
        })

    }
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        self.mapView.identify(self.graphicLayer, screenPoint: screenPoint, tolerance: 22, returnPopupsOnly: false, maximumResults: 1, completion: {
            result in
            if result.graphics.count > 0 {
                self.mapView.callout.title = "\(result.graphics[0].attributes["Match_addr"]!)"
                self.mapView.callout.detail = "\(result.graphics[0].attributes["DisplayY"]!)\u{00b0} \(result.graphics[0].attributes["DisplayX"]!)\u{00b0}"
                self.mapView.callout.show(for: result.graphics[0], tapLocation: mapPoint, animated: true)
            }else{
                self.mapView.callout.dismiss()
            }
        })
    }
    

}

