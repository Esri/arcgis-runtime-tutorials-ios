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

class ViewController: UIViewController, AGSMapViewLayerDelegate, UISearchBarDelegate, AGSLocatorDelegate, AGSCalloutDelegate, AGSRouteTaskDelegate {
                            
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var nextBtn: UIBarButtonItem!
    @IBOutlet weak var prevBtn: UIBarButtonItem!
    @IBOutlet weak var directionsLabel: UILabel!
    
    var graphicLayer:AGSGraphicsLayer!
    var locator:AGSLocator!
    var calloutTemplate:AGSCalloutTemplate!
    var routeTask:AGSRouteTask!
    var routeResult:AGSRouteResult!
    var currentDirectionGraphic:AGSDirectionGraphic!
    
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
        
        //Set the callout delegate
        self.mapView.callout.delegate = self
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
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar!) {
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
                let graphic = result.graphic
                self.graphicLayer.addGraphic(graphic)
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
    
    //MARK: AGSCalloutDelegate methods
    
    func didClickAccessoryButtonForCallout(callout: AGSCallout!) {
        let graphic = callout.representedObject as AGSGraphic
        let destinationLocation = graphic.geometry
        
        self.routeTo(destinationLocation)
    }
    
    func routeTo(destination:AGSGeometry) {
        //update the banner
        self.directionsLabel.text = "Routing"
        
        if self.routeTask == nil {
            self.routeTask = AGSRouteTask(URL: NSURL(string: "http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/Network/USA/NAServer/Route"))
            self.routeTask.delegate = self
        }
        
        let params = AGSRouteTaskParameters()
        
        let firstStop = AGSStopGraphic(geometry: self.mapView.locationDisplay.mapLocation(), symbol: nil, attributes: nil)
        let lastStop = AGSStopGraphic(geometry: destination, symbol: nil, attributes: nil)
        
        params.setStopsWithFeatures([firstStop, lastStop])
        
        //This returns entire route
        params.returnRouteGraphics = true
        //This returns turn by turn directions
        params.returnDirections = true
        
        //We don't want our stops reordered
        params.findBestSequence = false
        params.preserveFirstStop = true
        params.preserveLastStop = true
        
        //ensure the graphics are returned in our maps spatial reference
        params.outSpatialReference = self.mapView.spatialReference
        
        //Don't ignore invalid stops, raise error instead
        params.ignoreInvalidLocations = false
        
        self.routeTask.solveWithParameters(params)
    }
    
    //MARK: AGSRouteTaskDelegate methods
    
    func routeTask(routeTask: AGSRouteTask!, operation op: NSOperation!, didSolveWithResult routeTaskResult: AGSRouteTaskResult!) {
        //update our banner with status
        self.directionsLabel.text = "Route computed"
        
        //Remove existing route from map (if it exists)
        if self.routeResult != nil {
            self.graphicLayer.removeGraphic(self.routeResult.routeGraphic)
        }
        
        //Check if you got any results back
        if routeTaskResult.routeResults != nil {
            //you know that you are only dealing with 1 route...
            self.routeResult = routeTaskResult.routeResults[0] as? AGSRouteResult
            
            if self.routeResult != nil && self.routeResult.routeGraphic != nil {
                //symbolize the returned route graphic
                let yellowLine = AGSSimpleLineSymbol(color: UIColor.orangeColor(), width: 8.0)
                self.routeResult.routeGraphic.symbol = yellowLine
                
                //add the graphic to the graphics layer
                self.graphicLayer.addGraphic(self.routeResult.routeGraphic)
                
                //enable the next button so the suer can traverse directions
                self.nextBtn.enabled = true
                self.prevBtn.enabled = false
                self.currentDirectionGraphic = nil
                
                self.mapView.zoomToGeometry(self.routeResult.routeGraphic.geometry, withPadding: 100, animated: true)
                return
            }
        }
        //show aler if you didn't get results
        UIAlertView(title: "No Route", message: "No Routes Found", delegate: nil, cancelButtonTitle: "OK").show()
    }
    
    func routeTask(routeTask: AGSRouteTask!, operation op: NSOperation!, didFailSolveWithError error: NSError!) {
        //show aler if you didn't get results
        UIAlertView(title: "No Route", message: "No Routes Found : \(error.localizedDescription)", delegate: nil, cancelButtonTitle: "OK").show()
    }
    
    //MARK: actions
    
    @IBAction func prevBtnClicked(sender: AnyObject) {
        var index = 0
        if self.currentDirectionGraphic != nil {
            if let currentIndex = find(self.routeResult.directions.graphics as [AGSDirectionGraphic], self.currentDirectionGraphic) {
                index = currentIndex - 1
            }
        }
        self.displayDirectionForIndex(index)
    }
    
    @IBAction func nextBtnClicked(sender: AnyObject) {
        var index = 0
        if self.currentDirectionGraphic != nil {
            if let currentIndex = find(self.routeResult.directions.graphics as [AGSDirectionGraphic], self.currentDirectionGraphic) {
                index = currentIndex + 1
            }
        }
        self.displayDirectionForIndex(index)
    }
    
    func displayDirectionForIndex(index:Int) {
        //remove current direction graphic, so you can display next one
        self.graphicLayer.removeGraphic(self.currentDirectionGraphic)
        
        //get current direction and add it to the graphics layer
        let directions = self.routeResult.directions as AGSDirectionSet
        self.currentDirectionGraphic = directions.graphics[index] as AGSDirectionGraphic
        
        //highlight current manoeuver with a different symbol
        let cs = AGSCompositeSymbol()
        let sls1 = AGSSimpleLineSymbol()
        sls1.color = UIColor.whiteColor()
        sls1.style = .Solid
        sls1.width = 8
        cs.addSymbol(sls1)
    
        let sls2 = AGSSimpleLineSymbol()
        sls2.color = UIColor.redColor()
        sls2.style = .Dash
        sls2.width = 4
        cs.addSymbol(sls2)
        self.currentDirectionGraphic.symbol = cs
        
        self.graphicLayer.addGraphic(self.currentDirectionGraphic)
        
        //update banner
        self.directionsLabel.text = self.currentDirectionGraphic.text
        
        //soom to envelope of the current direction (expanded by a factor of 1.3)
        let env = self.currentDirectionGraphic.geometry.envelope.mutableCopy() as AGSMutableEnvelope
        env.expandByFactor(1.3)
        self.mapView.zoomToEnvelope(env, animated: true)
        
        //determine if you need to disable the next/prev button
        if index >= self.routeResult.directions.graphics.count - 1 {
            self.nextBtn.enabled = false
        }
        else {
            self.nextBtn.enabled = true
        }
        
        if index > 0 {
            self.prevBtn.enabled = true
        }
        else {
            self.prevBtn.enabled = false
        }
    }
    
}

