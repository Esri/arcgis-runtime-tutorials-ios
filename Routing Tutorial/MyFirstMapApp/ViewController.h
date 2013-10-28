//*
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


#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@interface ViewController : UIViewController <AGSMapViewLayerDelegate, UISearchBarDelegate, AGSLocatorDelegate, AGSCalloutDelegate, AGSRouteTaskDelegate>

@property (weak, nonatomic) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) AGSLocator *locator;

@property (nonatomic, strong) AGSCalloutTemplate *calloutTemplate;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *prevBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextBtn;
@property (weak, nonatomic) IBOutlet UILabel *directionsLabel;
@property (nonatomic, strong) AGSRouteTask *routeTask;
@property (nonatomic, strong) AGSRouteResult *routeResult;
@property (nonatomic, strong) AGSDirectionGraphic *currentDirectionGraphic;

- (IBAction)prevBtnClicked:(id)sender;
- (IBAction)nextBtnClicked:(id)sender;
- (void) routeTo:(AGSGeometry*)destination;
    
@end
