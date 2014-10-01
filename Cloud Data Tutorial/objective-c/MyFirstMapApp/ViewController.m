/*
 Copyright 2013 Esri
 
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

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AGSTiledMapServiceLayer *tiledLayer =
    [AGSTiledMapServiceLayer
     tiledMapServiceLayerWithURL:[NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"]];
    [self.mapView addMapLayer:tiledLayer withName:@"Basemap Tiled Layer"];
    
    //Set the map view's layerDelegate to self so that our
    //view controller is informed when map is loaded
    self.mapView.layerDelegate = self;
    
    // CLOUD DATA
    NSURL *featureLayerURL = [NSURL URLWithString:@"http://services.arcgis.com/oKgs2tbjK6zwTdvi/arcgis/rest/services/Major_World_Cities/FeatureServer/0"];
    AGSFeatureLayer *featureLayer = [AGSFeatureLayer featureServiceLayerWithURL:featureLayerURL mode:AGSFeatureLayerModeOnDemand];
    [self.mapView addMapLayer:featureLayer withName:@"CloudData"];
    
    // SYMBOLOGY
    AGSSimpleMarkerSymbol *featureSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:[UIColor colorWithRed:0 green:0.46 blue:0.68 alpha:1]];
    featureSymbol.size = CGSizeMake(7,7);
    featureSymbol.style = AGSSimpleMarkerSymbolStyleCircle;
    featureSymbol.outline = nil;
    featureLayer.renderer = [AGSSimpleRenderer simpleRendererWithSymbol:featureSymbol];
}

- (BOOL)prefersStatusBarHidden{
    return YES; //quick win for iOS 7
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - AGSMapViewLayerDelegate methods
- (void)mapViewDidLoad:(AGSMapView *) mapView {
    //do something now that the map is loaded
    //for example, show the current location on the map
    [mapView.locationDisplay startDataSource];
    
}


- (IBAction)showCountryPicker:(id)sender
{
    if(!self.countries){
        self.countries = @[@"None",@"US",@"Canada",@"France",@"Australia",@"Brazil"];
    }
    
    UIActionSheet* pickerSheet = [[UIActionSheet alloc]initWithFrame:CGRectMake(0, 0, 320, 410)];
    [pickerSheet showInView:self.view];
    [pickerSheet setBounds:CGRectMake(0, 0, 320, 410)];
    
    UIPickerView* countryPicker = [[UIPickerView alloc]initWithFrame:pickerSheet.bounds];
    countryPicker.delegate = self;
    countryPicker.dataSource = self;
    countryPicker.showsSelectionIndicator  = YES;
    [pickerSheet addSubview:countryPicker];
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.countries.count;
}

-(NSString *)pickerView:(UIPickerView *)pickerView
            titleForRow:(NSInteger)row
           forComponent:(NSInteger)component
{
    return self.countries[row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString* countryName = self.countries[row];
    
    AGSFeatureLayer *featureLayer = (AGSFeatureLayer *)[self.mapView mapLayerForName:@"CloudData"];
    
    if(!featureLayer.selectionSymbol){
        
        // SYMBOLOGY FOR WHERE CLAUSE SELECTION
        AGSSimpleMarkerSymbol *selectedFeatureSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbol];
        selectedFeatureSymbol.style = AGSSimpleMarkerSymbolStyleCircle;
        selectedFeatureSymbol.color = [UIColor colorWithRed:0.78 green:0.3 blue:0.19 alpha:1];
        selectedFeatureSymbol.size = CGSizeMake(10,10);
        featureLayer.selectionSymbol = selectedFeatureSymbol;
    }
    
    if(!featureLayer.queryDelegate){
        featureLayer.queryDelegate = self;
    }
    
    if ([countryName isEqualToString:@"None"])
    {
        // CLEAR SELECTION
        [featureLayer clearSelection];
    }
    else
    {
        // SELECT DATA WITH WHERE CLAUSE
        AGSQuery *selectQuery = [AGSQuery query];
        selectQuery.where = [NSString stringWithFormat:@"COUNTRY = '%@'", countryName];
        [featureLayer selectFeaturesWithQuery:selectQuery selectionMethod:AGSFeatureLayerSelectionMethodNew];
    }
    
    UIActionSheet* pickerSheet = (UIActionSheet*) pickerView.superview;
    [pickerSheet dismissWithClickedButtonIndex:0 animated:YES];
}

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation *)op didSelectFeaturesWithFeatureSet:(AGSFeatureSet *)featureSet
{
    
    // ZOOM TO SELECTED DATA
    AGSMutableEnvelope *env = nil;
    for (AGSGraphic *selectedFeature in featureSet.features)
    {
        if (env)
            [env unionWithEnvelope:selectedFeature.geometry.envelope];
        else
            env = [selectedFeature.geometry.envelope mutableCopy];
    }
    [self.mapView zoomToGeometry:env withPadding:20 animated:YES];
}
@end
