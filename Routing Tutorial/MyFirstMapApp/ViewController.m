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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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
    
    //set the callout's delegate
    self.mapView.callout.delegate = self;
}

- (BOOL)prefersStatusBarHidden{
    return YES; //quick win for iOS 7
}

#pragma mark - AGSMapViewLayerDelegate methods
- (void)mapViewDidLoad:(AGSMapView *) mapView {
    //do something now that the map is loaded
    //for example, show the current location on the map
    [mapView.locationDisplay startDataSource];
    
}

#pragma mark - AGSCalloutDelegate methods

- (void) didClickAccessoryButtonForCallout:(AGSCallout *)callout {
    AGSGraphic* graphic = (AGSGraphic*) callout.representedObject;
    AGSGeometry* destinationLocation = graphic.geometry;
    
    [self routeTo:destinationLocation];
    
}

- (void) routeTo:(AGSGeometry*)destination{
    
    if(!self.routeTask){
        self.routeTask = [AGSRouteTask routeTaskWithURL:[NSURL URLWithString:@"http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/Network/USA/NAServer/Route"] credential:nil];
        self.routeTask.delegate = self;
    }
    
    AGSRouteTaskParameters* params = [[AGSRouteTaskParameters alloc] init];
    
    AGSStopGraphic* firstStop = [AGSStopGraphic graphicWithGeometry:[self.mapView.locationDisplay mapLocation] symbol:nil attributes:nil];
    AGSStopGraphic* lastStop = [AGSStopGraphic graphicWithGeometry:destination symbol:nil attributes:nil ];
    [params setStopsWithFeatures:@[firstStop, lastStop]];
    
    //This returns entire route
    params.returnRouteGraphics = YES;
    //This returns turn-by-turn directions
    params.returnDirections = YES;
	
    //We don't want our stops reordered
    params.findBestSequence = NO;
    params.preserveFirstStop = YES;
    params.preserveLastStop = YES;
    params.outputGeometryPrecision = 5.0;
	params.outputGeometryPrecisionUnits = AGSUnitsMeters;
	
    // ensure the graphics are returned in our map's spatial reference
    params.outSpatialReference = self.mapView.spatialReference;
	
    //Don't ignore invalid stops, raise error instead
    params.ignoreInvalidLocations = NO;

    [self.routeTask solveWithParameters:params];
    
    self.directionsLabel.text = @"Routing...";
    
}

#pragma mark - AGSRouteTaskDelegate methods 

- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didSolveWithResult:(AGSRouteTaskResult *)routeTaskResult {
    
    // update our banner with status
    self.directionsLabel.text = @"Route computed.";
    
    //Remove existing route from map (if it exists)
    if(self.routeResult){
        [self.graphicsLayer removeGraphic:self.routeResult.routeGraphic];
    }
    
    //Check if we got any results back
    if (routeTaskResult.routeResults) {
        
        // we know that we are only dealing with 1 route...
        self.routeResult = routeTaskResult.routeResults[0];
        
        // symbolize the returned route graphic
        AGSSimpleLineSymbol* yellowLine = [AGSSimpleLineSymbol simpleLineSymbolWithColor:[UIColor orangeColor] width:8];
        self.routeResult.routeGraphic.symbol = yellowLine;
        
        // add the route graphic to the graphic's layer
        [self.graphicsLayer addGraphic:self.routeResult.routeGraphic];
        
        // enable the next button so the user can traverse directions
        self.nextBtn.enabled = YES;
        self.prevBtn.enabled = NO;
        self.currentDirectionGraphic = nil;
        
        [self.mapView zoomToGeometry:self.routeResult.routeGraphic.geometry withPadding:100 animated:YES];
        
    }else{
        //show alert if we didn't get results
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Route"
                                                        message:@"No Routes Found"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
    }
}

- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didFailSolveWithError:(NSError *)error {
	// the solve route failed...
	// let the user know
	UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Solve Route Failed"
												 message:[NSString stringWithFormat:@"Error: %@", error]
												delegate:nil
									   cancelButtonTitle:@"Ok"
									   otherButtonTitles:nil];
	[av show];
    self.directionsLabel.text = @"";
}

#pragma mark - Action methods

- (IBAction)nextBtnClicked:(id)sender {
    int index = 0;
    if(self.currentDirectionGraphic){
        index = [self.routeResult.directions.graphics indexOfObject:self.currentDirectionGraphic]+1;
    }
    [self displayDirectionForIndex:index];
    
}

- (IBAction)prevBtnClicked:(id)sender {
    int index = 0;
    if(self.currentDirectionGraphic){
        index = [self.routeResult.directions.graphics indexOfObject:self.currentDirectionGraphic]-1;
    }
    
    [self displayDirectionForIndex:index];
}

- (void)displayDirectionForIndex:(int)index{
    
    // remove current direction graphic, so we can display next one
    [self.graphicsLayer removeGraphic:self.currentDirectionGraphic];
    
    // get current direction and add it to the graphics layer
    AGSDirectionSet *directions = self.routeResult.directions;
    self.currentDirectionGraphic = [directions.graphics objectAtIndex:index];

    // highlight current manoeuver with a different symbol
    AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	AGSSimpleLineSymbol *sls1 = [AGSSimpleLineSymbol simpleLineSymbol];
	sls1.color = [UIColor whiteColor];
	sls1.style = AGSSimpleLineSymbolStyleSolid;
	sls1.width = 8;
	[cs addSymbol:sls1];
	AGSSimpleLineSymbol *sls2 = [AGSSimpleLineSymbol simpleLineSymbol];
	sls2.color = [UIColor redColor];
	sls2.style = AGSSimpleLineSymbolStyleDash;
	sls2.width = 4;
	[cs addSymbol:sls2];
    
    self.currentDirectionGraphic.symbol = cs;
    [self.graphicsLayer addGraphic:self.currentDirectionGraphic];
    
    // update banner
    self.directionsLabel.text = self.currentDirectionGraphic.text;
    
    // zoom to envelope of the current direction (expanded by factor of 1.3)
    AGSMutableEnvelope *env = [self.currentDirectionGraphic.geometry.envelope mutableCopy];
    [env expandByFactor:1.3];
    [self.mapView zoomToEnvelope:env animated:YES];
    
    // determine if we need to disable a next/prev button
    if (index >= self.routeResult.directions.graphics.count - 1) {
        self.nextBtn.enabled = NO;
    }else{
        self.nextBtn.enabled = YES;
        
    }
    
    if (index > 0) {
        self.prevBtn.enabled = YES;
    }else{
        self.prevBtn.enabled = NO;
    }
    
    
}




#pragma mark - UISearchBarDelegate methods

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    //Hide the keyboard
    [searchBar resignFirstResponder];
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

#pragma mark - AGSLocatorDelegate methods
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
            //Assign the callout template to each graphic
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
