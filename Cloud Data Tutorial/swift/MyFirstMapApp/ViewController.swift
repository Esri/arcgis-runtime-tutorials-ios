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

class ViewController: UIViewController, AGSMapViewLayerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, AGSFeatureLayerQueryDelegate {
                            
    @IBOutlet weak var mapView: AGSMapView!
    let countries = ["None", "US", "Canada", "France", "Australia", "Brazil"]
    var countryPicker: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //code from previous tutorial to add a basemap tiled layer
        //Add a basemap tiled layer
        let url = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer")
        let tiledLayer = AGSTiledMapServiceLayer(URL: url)
        self.mapView.addMapLayer(tiledLayer, withName: "Basemap Tiled Layer")
        
        //Set the map view's layer delegate
        self.mapView.layerDelegate = self
        
        //CLOUD DATA
        let featureLayerURL = NSURL(string: "http://services.arcgis.com/oKgs2tbjK6zwTdvi/arcgis/rest/services/Major_World_Cities/FeatureServer/0")
        let featureLayer = AGSFeatureLayer(URL: featureLayerURL, mode: .OnDemand)
        self.mapView.addMapLayer(featureLayer, withName: "CloudData")
        
        //SYMBOLOGY
        let featureSymbol = AGSSimpleMarkerSymbol(color:UIColor(red: 0, green: 0.46, blue: 0.68, alpha: 1))
        featureSymbol.size = CGSizeMake(7, 7)
        featureSymbol.style = .Circle
        featureSymbol.outline = nil
        featureLayer.renderer = AGSSimpleRenderer(symbol: featureSymbol)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    //MARK: - map view layer delegate methods
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        //do something now that the map is loaded
        //for example, show the current location on the map
        mapView.locationDisplay.startDataSource()
    }
    
    //MARK: - Actions
    
    @IBAction func showCountryPicker(sender:AnyObject) {
        //create the picker view for the first time
        if self.countryPicker == nil {
            self.countryPicker = UIPickerView()
            self.countryPicker.delegate = self
            self.countryPicker.dataSource = self
            self.countryPicker.showsSelectionIndicator = true
            self.countryPicker.backgroundColor = UIColor.whiteColor()
            self.view.addSubview(self.countryPicker)
            
            self.countryPicker.setTranslatesAutoresizingMaskIntoConstraints(false)
            //leading constraint
            self.view.addConstraint(NSLayoutConstraint(item: self.countryPicker, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0))
            //trailing constraint
            self.view.addConstraint(NSLayoutConstraint(item: self.countryPicker, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 0))
            //bottom constraint
            self.view.addConstraint(NSLayoutConstraint(item: self.countryPicker, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0))
        }
        
        self.countryPicker.hidden = false
    }
    
    //MARK: Picker view data source methods
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.countries.count
    }

    //MARK: - Picker view delegate methods
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
            return self.countries[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let countryName = self.countries[row]
        
        let featureLayer = self.mapView.mapLayerForName("CloudData") as AGSFeatureLayer
        
        if featureLayer.selectionSymbol == nil {
            //SYMBOLOGY FOR WHERE CLAUSE SELECTION
            let selectedFeatureSymbol = AGSSimpleMarkerSymbol()
            selectedFeatureSymbol.style = .Circle
            selectedFeatureSymbol.color = UIColor(red: 0.78, green: 0.3, blue: 0.19, alpha: 1)
            selectedFeatureSymbol.size = CGSizeMake(10, 10)
            featureLayer.selectionSymbol = selectedFeatureSymbol
        }
        
        if featureLayer.queryDelegate == nil {
            featureLayer.queryDelegate = self
        }
        
        if countryName == "None" {
            //CLEAR SELECTION
            featureLayer.clearSelection()
        }
        else {
            //SELECT DATA WITH WHERE CLAUSE
            let selectQuery = AGSQuery()
            let queryString = "COUNTRY = '\(countryName)'"
            selectQuery.whereClause = queryString
            featureLayer.selectFeaturesWithQuery(selectQuery, selectionMethod: .New)
        }
        
        //DISMISS PICKER
        self.countryPicker.hidden = true
    }
    
    
    //MARK: - Feature layer query delegate methods
    
    func featureLayer(featureLayer: AGSFeatureLayer!, operation op: NSOperation!, didSelectFeaturesWithFeatureSet featureSet: AGSFeatureSet!) {
        //ZOOM TO SELECTED DATA
        var env:AGSMutableEnvelope!
        for selectedFeature in featureSet.features as [AGSGraphic]{
            if env != nil {
                env.unionWithEnvelope(selectedFeature.geometry.envelope)
            }
            else {
                env = selectedFeature.geometry.envelope.mutableCopy() as AGSMutableEnvelope
            }
        }
        self.mapView.zoomToGeometry(env, withPadding: 20, animated: true)
    }
    
    func featureLayer(featureLayer: AGSFeatureLayer!, operation op: NSOperation!, didFailSelectFeaturesWithError error: NSError!) {
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: nil).show()
    }
}
