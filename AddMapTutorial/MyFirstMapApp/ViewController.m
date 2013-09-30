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


@end
