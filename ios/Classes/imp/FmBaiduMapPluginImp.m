#import <Flutter/Flutter.h>
#import <BMKLocationkit/BMKLocationComponent.h>
#include "FmBaiduMapPluginImp.h"
#include "FmBaiduLocationImpClientBaidu.h"
#include "FmBaiduMapViewFactory.h"
#import <BaiduMapAPI_Base/BMKTypes.h>
#import <BaiduMapAPI_Utils/BMKGeometry.h>


@interface FmBaiduMapPluginImp() <BMKLocationAuthDelegate>

@end


@implementation FmBaiduMapPluginImp {
    NSObject<FlutterPluginRegistrar> *_registrar;
    NSMutableDictionary<NSString*,FmBaiduLocationImpClient*> *_locations;
    // MapView
}

-(id)initWithRegist:(NSObject<FlutterPluginRegistrar> *)registrar{
    _registrar = registrar;
    _locations = [[NSMutableDictionary alloc] init];
    [FmBaiduMapViewFactory registerWithRegistrar:registrar];
    return self;
}

- (void)newInstanceLocation:(NSMutableDictionary *)arg result:(FlutterResult)result{
    NSString* name = [arg  valueForKey:@"name"];
    //    BOOL isBaidu = [arg  valueForKey:@"isBaidu"];
    FmBaiduLocationImpClientBaidu* client = [[FmBaiduLocationImpClientBaidu alloc] initWithRegist:_registrar name:name];
    [client initInstance];
    [_locations setValue:client forKey:name];
    result(name);
}


- (void)getDistance:(NSDictionary *)arg result:(FlutterResult)result {
    
    CLLocationCoordinate2D c1 = CLLocationCoordinate2DMake([arg[@"latitude1"] doubleValue], [arg[@"longitude1"] doubleValue]);
    CLLocationCoordinate2D c2 = CLLocationCoordinate2DMake([arg[@"latitude2"] doubleValue], [arg[@"longitude2"] doubleValue]);
    
    BMKMapPoint point1 = BMKMapPointForCoordinate(c1);
    BMKMapPoint point2 = BMKMapPointForCoordinate(c2);
    double distance = BMKMetersBetweenMapPoints(point1, point2);
    
    result(@(distance));
}



/**
 *@brief 返回授权验证错误
 *@param iError 错误号 : 为0时验证通过，具体参加BMKLocationAuthErrorCode
 */
- (void)onCheckPermissionState:(BMKLocationAuthErrorCode)iError {
    if ( iError == BMKLocationAuthErrorSuccess){
        NSLog(@"success=======");
    } else {
        NSLog(@"ffffff--------");
    }
}
+ (void)initSDK {
    [[BMKLocationAuth sharedInstance] checkPermisionWithKey:@"" authDelegate:self];
}

@end
