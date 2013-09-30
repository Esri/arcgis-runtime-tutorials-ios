#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@interface ViewController : UIViewController <AGSMapViewLayerDelegate, AGSFeatureLayerQueryDelegate , UIPickerViewDelegate, UIPickerViewDataSource>
@property (weak, nonatomic) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) NSArray *countries;
- (IBAction)showCountryPicker:(id)sender;

@end
