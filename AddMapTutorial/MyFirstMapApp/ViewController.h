#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@interface ViewController : UIViewController <AGSMapViewLayerDelegate>
@property (weak, nonatomic) IBOutlet AGSMapView *mapView;

@end
