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

class ViewController: UIViewController, AGSMapViewLayerDelegate, UISearchBarDelegate, AGSLocatorDelegate {
                            
    @IBOutlet weak var mapView: AGSMapView!
    var graphicLayer:AGSGraphicsLayer!
    var locator:AGSLocator!
    var calloutTemplate:AGSCalloutTemplate!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Add a basemap tiled layer
        let url = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer")
        let tiledLayer = AGSTiledMapServiceLayer(URL: url)
        self.mapView.addMapLayer(tiledLayer, withName: "Basemap Tiled Layer")
        
        //Set the map view's layer delegate
        self.mapView.layerDelegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    //MARK: map view layer delegate methods
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        //do something now that the map is loaded
        //for example, show the current location on the map
        mapView.locationDisplay.startDataSource()
    }
    
    //MARK: search bar delegate methods
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        //Hide the keyboard
        searchBar.resignFirstResponder()
        
        if self.graphicLayer == nil {
            //Add a graphics layer to the map. This layer will hold geocoding results
            self.graphicLayer = AGSGraphicsLayer()
            self.mapView.addMapLayer(self.graphicLayer, withName:"Results")
            
            //Assign a simple renderer to the layer to display results as pushpins
            let pushpin = AGSPictureMarkerSymbol(imageNamed: "BluePushpin.png")
            pushpin.offset = CGPointMake(9, 16)
            pushpin.leaderPoint = CGPointMake(-9, 11)
            let renderer = AGSSimpleRenderer(symbol: pushpin)
            self.graphicLayer.renderer = renderer
        }
        else {
            //Clear out previous results if we already have a graphics layer
            self.graphicLayer.removeAllGraphics()
        }
        
        
        if self.locator == nil {
            //Create the AGSLocator pointing to the geocode service on ArcGIS Online
            //Set the delegate so that we are informed through AGSLocatorDelegate methods
            let url = NSURL(string: "http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer")
            self.locator = AGSLocator(URL: url)
            self.locator.delegate = self
        }
        
        //Set the parameters
        let params = AGSLocatorFindParameters()
        params.text = searchBar.text
        params.outFields = ["*"]
        params.outSpatialReference = self.mapView.spatialReference
        params.location = AGSPoint(x: 0, y: 0, spatialReference: nil)
        
        //Kick off the geocoding operation
        //This will invoke the geocode service on a background thread
        self.locator.findWithParameters(params)
    }
    
    //MARK: AGSLocator delegate methods
    
    func locator(locator: AGSLocator!, operation op: NSOperation!, didFind results: [AnyObject]!) {
        if results == nil || results.count == 0 {
            //show alert if we didn't get results
            UIAlertView(title: "No Results", message: "No Results Found", delegate: nil, cancelButtonTitle: "OK").show()
        }
        else {
            //Create a callout template if we haven't done so already
            if self.calloutTemplate == nil {
                self.calloutTemplate = AGSCalloutTemplate()
                self.calloutTemplate.titleTemplate = "${Match_addr}"
                self.calloutTemplate.detailTemplate = "${DisplayY}\u{00b0} ${DisplayX}\u{00b0}"
                
                //Assign the callout template to the layer so that all graphics within this layer
                //display their information in the callout in the same manner
                self.graphicLayer.calloutDelegate = self.calloutTemplate
            }
            
            //Add a graphic for each result
            for result in results as [AGSLocatorFindResult] {
                self.graphicLayer.addGraphic(result.graphic)
            }
            
            //Zoom in to the results
            let extent = self.graphicLayer.fullEnvelope.mutableCopy() as AGSMutableEnvelope
            extent.expandByFactor(1.5)
            self.mapView.zoomToEnvelope(extent, animated: true)
        }
    }
    
    func locator(locator: AGSLocator!, operation op: NSOperation!, didFailLocationsForAddress error: NSError!) {
        UIAlertView(title: "Locator Failed", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
    }
}

