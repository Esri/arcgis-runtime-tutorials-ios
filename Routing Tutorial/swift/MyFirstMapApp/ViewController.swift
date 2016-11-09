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

class ViewController: UIViewController, UISearchBarDelegate, AGSCalloutDelegate, AGSGeoViewTouchDelegate {
                            
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var nextBtn: UIBarButtonItem!
    @IBOutlet weak var prevBtn: UIBarButtonItem!
    @IBOutlet weak var directionsLabel: UILabel!
    
    var graphicLayer:AGSGraphicsOverlay!
    var locator:AGSLocatorTask!
    var routeTask:AGSRouteTask!
    var routeResult:AGSRouteResult!
    var currentDirectionGraphic:AGSGraphic!
    var currentDirectionIndex = 0
    
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
        self.mapView.callout.delegate = self
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
    
    
    //MARK: AGSCalloutDelegate methods
    
    @objc(didTapAccessoryButtonForCallout:) func didTapAccessoryButton(for callout: AGSCallout) {
        
        self.currentDirectionGraphic = nil
        self.currentDirectionIndex = 0
        
        let graphic = callout.representedObject as! AGSGraphic
        let destinationLocation = graphic.geometry!
        
        self.routeTo(destinationLocation)
    }
    
    
    func routeTo(_ destination:AGSGeometry) {
        //update the banner
        self.directionsLabel.text = "Routing..."
        
        if self.routeTask == nil {
            self.routeTask = AGSRouteTask(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/Route")!)
        
        }
        
      self.routeTask.defaultRouteParameters { (params, error) in
            if let params = params {
                let firstStop = AGSStop(point: self.mapView.locationDisplay.mapLocation!)
                firstStop.name = "Origin"
                let lastStop = AGSStop(point: destination as! AGSPoint)
                lastStop.name = "Destination"
                
                
                params.setStops([firstStop, lastStop])
                
                //This returns entire route
                params.returnRoutes = true
                //This returns turn by turn directions
                params.returnDirections = true
                
                //We don't want our stops reordered
                params.findBestSequence = false
                params.preserveFirstStop = true
                params.preserveLastStop = true
                
                //ensure the graphics are returned in our maps spatial reference
                params.outputSpatialReference = self.mapView.spatialReference
                
                self.routeTask.solveRoute(with: params, completion: {
                    (result,error) in
                    
                    //update our banner with status
                    self.directionsLabel.text = "Route computed"
                    
                    //Remove existing route from map (if it exists)
                    if self.routeResult != nil {
                        self.graphicLayer.graphics.removeAllObjects()
                    }
                    
                    //Check if you got any results back
                    if let result = result {
                        //you know that you are only dealing with 1 route...
                        self.routeResult = result
                        
                        //symbolize the returned route geometry
                        
                        let yellowLine = AGSSimpleLineSymbol(style: .solid, color: UIColor.orange, width: 8)
                        let routeGraphic = AGSGraphic(geometry: self.routeResult.routes[0].routeGeometry!, symbol: yellowLine, attributes: nil)
                        
                        //add the graphic to the graphics layer
                        self.graphicLayer.graphics.add(routeGraphic)
                        
                        //enable the next button so the suer can traverse directions
                        self.nextBtn.isEnabled = true
                        self.prevBtn.isEnabled = false
                        
                        self.currentDirectionGraphic = AGSGraphic()
                        self.graphicLayer.graphics.add(self.currentDirectionGraphic)
                        
                        self.mapView.setViewpointGeometry(routeGraphic.geometry!, padding:30, completion: nil)
                    }else if let error = error {
                        
                        let alert = UIAlertController(title: "No route found", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        
                    }
                })
            }
        }
        

    }
    

    
    //MARK: actions
    
    @IBAction func prevBtnClicked(_ sender: AnyObject) {
        if self.currentDirectionIndex > 0 {
            self.currentDirectionIndex = self.currentDirectionIndex - 1
            self.displayDirectionForIndex(self.currentDirectionIndex)
        }
    }

    @IBAction func nextBtnClicked(_ sender: AnyObject) {
        if self.currentDirectionIndex < self.routeResult.routes[0].directionManeuvers.count {
            self.currentDirectionIndex = self.currentDirectionIndex + 1
            self.displayDirectionForIndex(self.currentDirectionIndex)
        }
    }

    func displayDirectionForIndex(_ index:Int) {
        
        //update the graphic to display current maneuver
        self.currentDirectionGraphic.geometry = self.routeResult.routes[0].directionManeuvers[self.currentDirectionIndex].geometry
        
        //highlight current manoeuver with a different symbol
        let sls1 = AGSSimpleLineSymbol()
        sls1.color = UIColor.white
        sls1.style = .solid
        sls1.width = 8
    
        let sls2 = AGSSimpleLineSymbol()
        sls2.color = UIColor.red
        sls2.style = .dash
        sls2.width = 4

        
        self.currentDirectionGraphic.symbol = AGSCompositeSymbol(symbols: [sls1,sls2])
        
        
        //update banner
        self.directionsLabel.text = self.routeResult.routes[0].directionManeuvers[self.currentDirectionIndex].directionText
        
        //soom to envelope of the current direction (expanded by a factor of 1.3)
        self.mapView.setViewpointGeometry(self.currentDirectionGraphic.geometry!, padding: 30, completion: nil)
        
        //determine if you need to disable the next/prev button
        if self.currentDirectionIndex < self.routeResult.routes[0].directionManeuvers.count - 1  {
            self.nextBtn.isEnabled = true
        }
        else {
            self.nextBtn.isEnabled = false
        }
        
        if self.currentDirectionIndex > 0 {
            self.prevBtn.isEnabled = true
        }
        else {
            self.prevBtn.isEnabled = false
        }
    }
    
}

