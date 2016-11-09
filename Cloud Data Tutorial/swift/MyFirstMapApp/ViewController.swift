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

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
                            
    @IBOutlet weak var mapView: AGSMapView!
    let countries = ["None", "United States", "Canada", "France", "Australia", "Brazil"]
    var countryPicker: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Initialize map with Light Gray Canvas basemap
        self.mapView.map = AGSMap(basemapType: .lightGrayCanvas, latitude: 0, longitude: 0, levelOfDetail: 0)
        
        //Start the location display
        self.mapView.locationDisplay.start(completion: nil)

        //CLOUD DATA
        let featureLayerURL = URL(string: "https://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/World_Cities/FeatureServer/0")
        let featureLayer = AGSFeatureLayer(featureTable: AGSServiceFeatureTable(url:featureLayerURL!))
        featureLayer.minScale = 0
        featureLayer.maxScale = 0
        featureLayer.selectionColor = UIColor.orange
        self.mapView.map!.operationalLayers.add(featureLayer)
        
        //SYMBOLOGY
        let featureSymbol = AGSSimpleMarkerSymbol(style: .circle, color: UIColor(red: 0, green: 0.46, blue: 0.68, alpha: 1), size: 7)
        featureLayer.renderer = AGSSimpleRenderer(symbol: featureSymbol)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    //MARK: - Actions
    
    @IBAction func showCountryPicker(_ sender:AnyObject) {
        //create the picker view for the first time
        if self.countryPicker == nil {
            self.countryPicker = UIPickerView()
            self.countryPicker.delegate = self
            self.countryPicker.dataSource = self
            self.countryPicker.showsSelectionIndicator = true
            self.countryPicker.backgroundColor = UIColor.white
            self.view.addSubview(self.countryPicker)
            
            self.countryPicker.translatesAutoresizingMaskIntoConstraints = false
            //leading constraint
            self.view.addConstraint(NSLayoutConstraint(item: self.countryPicker, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0))
            //trailing constraint
            self.view.addConstraint(NSLayoutConstraint(item: self.countryPicker, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0))
            //bottom constraint
            self.view.addConstraint(NSLayoutConstraint(item: self.countryPicker, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
        }
        
        self.countryPicker.isHidden = false
    }
    
    //MARK: Picker view data source methods
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.countries.count
    }

    //MARK: - Picker view delegate methods
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return self.countries[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let countryName = self.countries[row]
        
        let featureLayer = self.mapView.map!.operationalLayers[0] as! AGSFeatureLayer
        
        if countryName == "None" {
            //CLEAR SELECTION
            featureLayer.clearSelection()
        }
        else {
            //SELECT DATA WITH WHERE CLAUSE
            let query = AGSQueryParameters()
            query.whereClause =  "CNTRY_NAME  = '\(countryName)'"
            featureLayer.selectFeatures(withQuery: query, mode: .new, completion:{
                (result, error) in
                let bldr = AGSEnvelopeBuilder(spatialReference:self.mapView.map!.spatialReference)
                if let r = result{
                    let enumr = r.featureEnumerator()
                    for feature in enumr {
                        bldr.union(with:(feature as! AGSFeature).geometry!.extent)
                    }
                    self.mapView.setViewpointGeometry(bldr.toGeometry(),completion:nil)
                }
                //TODO : else, display error
            })

        }
        
        //DISMISS PICKER
        self.countryPicker.isHidden = true
    }
    
    
    //MARK: - Feature layer query delegate methods
//    
//    func featureLayer(_ featureLayer: AGSFeatureLayer!, operation op: Operation!, didSelectFeaturesWithFeatureSet featureSet: AGSFeatureSet!) {
//        //ZOOM TO SELECTED DATA
//        var env:AGSMutableEnvelope!
//        for selectedFeature in featureSet.features as! [AGSGraphic]{
//            if env != nil {
//                env.unionWithEnvelope(selectedFeature.geometry.envelope)
//            }
//            else {
//                env = selectedFeature.geometry.envelope.mutableCopy() as! AGSMutableEnvelope
//            }
//        }
//        self.mapView.zoomToGeometry(env, withPadding: 20, animated: true)
//    }
//    
//    func featureLayer(_ featureLayer: AGSFeatureLayer!, operation op: Operation!, didFailSelectFeaturesWithError error: NSError!) {
//        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: nil).show()
//    }
}
