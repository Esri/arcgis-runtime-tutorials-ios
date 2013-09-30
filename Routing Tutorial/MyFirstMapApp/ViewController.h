// Copyright 2013 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//
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
