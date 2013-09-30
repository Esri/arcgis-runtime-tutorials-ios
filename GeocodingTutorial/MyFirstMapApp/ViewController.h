#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@interface ViewController : UIViewController <AGSMapViewLayerDelegate, UISearchBarDelegate, AGSLocatorDelegate, AGSCalloutDelegate>

@property (weak, nonatomic) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) AGSLocator *locator;
@property (nonatomic, strong) AGSCalloutTemplate *calloutTemplate;

@end
