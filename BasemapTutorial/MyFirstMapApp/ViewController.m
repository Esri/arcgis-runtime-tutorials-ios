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


- (IBAction)basemapChanged:(id)sender {

    NSURL* basemapURL ;
    UISegmentedControl* segControl = (UISegmentedControl*)sender;
    switch (segControl.selectedSegmentIndex) {
        case 0: //gray
            basemapURL = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"];
            break;
        case 1: //oceans
            basemapURL = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/Ocean_Basemap/MapServer"];
            break;
        case 2: //nat geo
            basemapURL = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/NatGeo_World_Map/MapServer"];
            break;
        case 3: //topo
            basemapURL = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"];
            break;
        case 4: //sat
            basemapURL = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer"];
            break;
        default:
            break;
    }
    
    //remove existing basemap layer
    [self.mapView removeMapLayerWithName:@"Basemap Tiled Layer"];
    
    //add new layer
    AGSTiledMapServiceLayer* newBasemapLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:basemapURL];
    newBasemapLayer.name = @"Basemap Tiled Layer";
    [self.mapView insertMapLayer:newBasemapLayer atIndex:0];
}
@end
