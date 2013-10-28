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

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    //Hide the keyboard
    [searchBar resignFirstResponder];
    
    if(!self.graphicsLayer){
        //Add a graphics layer to the map. This layer will hold geocoding results
        self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
        [self.mapView addMapLayer:self.graphicsLayer withName:@"Results"];
        
        //Assign a simple renderer to the layer to display results as pushpins
        AGSPictureMarkerSymbol* pushpin = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"BluePushpin.png"];
        pushpin.offset = CGPointMake(9,16);
        pushpin.leaderPoint = CGPointMake(-9, 11);
        AGSSimpleRenderer* renderer = [AGSSimpleRenderer simpleRendererWithSymbol:pushpin];
        self.graphicsLayer.renderer = renderer;
    }else{
        //Clear out previous results if we already have a graphics layer
        [self.graphicsLayer removeAllGraphics];
    }
    
    
    if(!self.locator){
        //Create the AGSLocator pointing to the geocode service on ArcGIS Online
        //Set the delegate so that we are informed through AGSLocatorDelegate methods
        self.locator = [AGSLocator locatorWithURL:[NSURL URLWithString:@"http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer"]];
        self.locator.delegate = self;
    }
    
    //Set the parameters
    AGSLocatorFindParameters* params = [[AGSLocatorFindParameters alloc]init];
    params.text = searchBar.text;
    params.outFields = @[@"*"];
    params.outSpatialReference = self.mapView.spatialReference;
    params.location = [AGSPoint pointWithX:0 y:0 spatialReference:nil];
    
    //Kick off the geocoding operation.
    //This will invoke the geocode service on a background thread.
    [self.locator findWithParameters:params];
    
    
}

- (void)locator:(AGSLocator *)locator operation:(NSOperation *)op didFind:(NSArray *)results {
    if (results == nil || [results count] == 0)
    {
        //show alert if we didn't get results
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Results"
                                                        message:@"No Results Found"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
    }
    else
    {
        //Create a callout template if we haven't done so already
        if(!self.calloutTemplate){
            self.calloutTemplate = [[AGSCalloutTemplate alloc]init];
            self.calloutTemplate.titleTemplate = @"${Match_addr}";
            self.calloutTemplate.detailTemplate = [NSString stringWithFormat:@"${DisplayY}%@ ${DisplayX}%@", @"\u00b0", @"\u00b0"];
            
            //Assign the callout template to the layer so that all graphics within this layer
            //display their information in the callout in the same manner
            self.graphicsLayer.calloutDelegate = self.calloutTemplate;
        }

        //Add a graphic for each result
        for (AGSLocatorFindResult* result in results) {
            AGSGraphic* graphic = result.graphic;
            [self.graphicsLayer addGraphic:graphic];
        }
        
        //Zoom in to the results
        AGSMutableEnvelope *extent = [self.graphicsLayer.fullEnvelope mutableCopy];
        [extent expandByFactor:1.5];
        [self.mapView zoomToEnvelope:extent animated:YES];
    }
}
- (void)locator:(AGSLocator *)locator operation:(NSOperation *)op didFailLocationsForAddress:(NSError *)error
{
    //The location operation failed, display the error
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Locator Failed"
                                                    message:[NSString stringWithFormat:@"Error: %@", error.description]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    
    [alert show];
}

@end
