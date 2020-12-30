#include "FmBaiduLocationImpClientBaidu.h"
#import <CoreLocation/CoreLocation.h>
#import <BaiduMapAPI_Base/BMKBaseComponent.h>
#import <BMKLocationKit/BMKLocationComponent.h>
#import <BMKLocationKit/BMKLocationManager.h>

@interface FmBaiduLocationImpClientBaidu() <CLLocationManagerDelegate, BMKLocationManagerDelegate, BMKLocationAuthDelegate>

@property (nonatomic, strong) FmToolsBase *invoker;

@property (nonatomic, strong) BMKMapManager *mapManager;

@end

@implementation FmBaiduLocationImpClientBaidu{
    BMKLocationManager *_locationManager;
    CLLocationManager *locationManagerPer;
}

-(id)initWithRegist:(NSObject<FlutterPluginRegistrar> *)registrar name:(NSString *)name {
    
    self.invoker = [[FmToolsBase alloc] initWithRegist:registrar name:name imp:self];
    return self;
}
/**
 *定位失败后，会调用此函数
 *@param mapView 地图View
 *@param error 错误号，参考CLError.h中定义的错误号
 */
- (void)didFailToLocateUserWithError:(NSError *)error {
    NSLog(@"location error:%@", [error localizedDescription]);
    if(error.code == 0) {
        return;
    }
    
    int stat = [CLLocationManager authorizationStatus];
    if(stat == kCLAuthorizationStatusNotDetermined || stat == kCLAuthorizationStatusRestricted || stat == kCLAuthorizationStatusDenied){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"定位服务未开启或受限"
                                                        message:@"可在系统设置中开启定位服务\n(设置>隐身>定位服务)"
                                                       delegate:nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        [alert show];
        //        [alert release];
    } else {
        //        emit FmMapView_M::g_mapLocation->receiveLoctionError(QString::fromNSString([error localizedDescription]));
    }
}
- (NSObject *)start {
    if([CLLocationManager locationServicesEnabled]) {
        locationManagerPer = [[CLLocationManager alloc] init];
        
        locationManagerPer.pausesLocationUpdatesAutomatically = NO ;
        //ios8以后需要添加如下授权，以前的可直接start（显示要使用定位的警告框,提示你是否允许使用定位）
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0) {
            //[locationManager requestWhenInUseAuthorization]; //使用时授权(只用这个的话后台时不能定位)
            [locationManagerPer requestWhenInUseAuthorization]; // 永久授权（前台后台都能定位）
        }
    }
    [_locationManager startUpdatingLocation];
    return @(true);
}
-(NSObject *)stop {
    [_locationManager stopUpdatingLocation];
    return @(true);
}
-(NSObject *)isStarted {
    BOOL isStartes = [self locating];
    return @(isStartes);
}
-(BOOL)locating {
    if ([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied) {
        return true;
    }
    return false;
}
-(void)initInstance {
    
    // 要使用百度地图，请先启动BaiduMapManager
    self.mapManager = [[BMKMapManager alloc]init];
    
    /**
     *百度地图SDK所有接口均支持百度坐标（BD09）和国测局坐标（GCJ02），用此方法设置您使用的坐标类型.
     *默认是BD09（BMK_COORDTYPE_BD09LL）坐标.
     *如果需要使用GCJ02坐标，需要设置CoordinateType为：BMK_COORDTYPE_COMMON.
     */
    if ([BMKMapManager setCoordinateTypeUsedInBaiduMapSDK:BMK_COORDTYPE_BD09LL]) {
        NSLog(@"经纬度类型设置成功");
    } else {
        NSLog(@"经纬度类型设置失败");
    }
    BOOL ret = [_mapManager start:@"uEYq6NGO3nSKNaZzYERYhEoeKVe910iL" generalDelegate:nil];
    
    if (!ret) {
        NSLog(@"manager start failed!");
    }
    
    
    //初始化实例
    _locationManager = [[BMKLocationManager alloc] init];
    //设置返回位置的坐标系类型
    _locationManager.coordinateType = BMKLocationCoordinateTypeBMK09LL;
    //设置距离过滤参数
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    //设置预期精度参数
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    //设置应用位置类型
    _locationManager.activityType = CLActivityTypeAutomotiveNavigation;
    //设置是否自动停止位置更新
    _locationManager.pausesLocationUpdatesAutomatically = NO;
    //设置是否允许后台定位
    //_locationManager.allowsBackgroundLocationUpdates = YES;
    //设置位置获取超时时间
    _locationManager.locationTimeout = 10;
    //设置获取地址信息超时时间
    _locationManager.reGeocodeTimeout = 10;
    _locationManager.delegate = self;
    
    [self initSDK];
    
}
/**
  * @brief 当定位发生错误时，会调用代理的此方法。
  * @param manager 定位 BMKLocationManager 类。
  * @param error 返回的错误，参考 CLError 。
 */
-(void)BMKLocationManager:(BMKLocationManager *_Nonnull)manager didFailWithError:(NSError  *_Nullable)error {
    NSLog(@"serial loc error = %@", error);
}


-(void)BMKLocationManager:(BMKLocationManager *_Nonnull)manager didUpdateLocation:(BMKLocation *_Nullable)location orError:(NSError *_Nullable)error {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @(location.location.coordinate.latitude), @"latitude",
                          @(location.location.coordinate.longitude), @"longitude",
                          nil];
    //    [dict setValue:location.location.coordinate.latitude forKey:@"latitude"];
    //    [dict setValue:location.location.coordinate.longitude forKey:@"longitude"];
    //    HashMap<String, Object> jsonObject = new HashMap();
    //    jsonObject.put("coordType", "Baidu");
    //    jsonObject.put("time", System.currentTimeMillis());
    //    jsonObject.put("speed", bdLocation.getSpeed());
    //    jsonObject.put("altitude", bdLocation.getAltitude());
    //    jsonObject.put("latitude", bdLocation.getLatitude());
    //    jsonObject.put("longitude", bdLocation.getLongitude());
    //    jsonObject.put("bearing", bdLocation.getDirection());
    [self.invoker invokeMethod:@"onLocation" arg:dict];
}

-(void)initSDK {
    //    R8lzapOh0YZDfE5x6OAtIzdGWpUS9nBx
    [[BMKLocationAuth sharedInstance] checkPermisionWithKey:@"uEYq6NGO3nSKNaZzYERYhEoeKVe910iL" authDelegate:self];
}

-(NSObject *)dispose {
    [_locationManager stopUpdatingLocation];
    [self.invoker dispose];
    self.invoker = nil;
    _locationManager = nil;
    return nil;
}


#pragma mark --  BMKLocationAuthDelegate method
-(void)onCheckPermissionState:(BMKLocationAuthErrorCode)iError {
    
    if (iError == BMKLocationAuthErrorSuccess) {
                
        __weak typeof(self) weakSelf = self;
        [_locationManager requestLocationWithReGeocode:YES withNetworkState:YES completionBlock:^(BMKLocation  *_Nullable location, BMKLocationNetworkState state, NSError  *_Nullable error) {
            
            if (error) {
                NSLog(@"locError:{%ld - %@};", (long)error.code, error.localizedDescription);
            }
            if (location) {
                //得到定位信息，添加annotation
                
                NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @(location.location.coordinate.latitude),@"latitude",
                                      @(location.location.coordinate.longitude),@"longitude",
                                      nil];
                
                [weakSelf.invoker invokeMethod:@"onLocation" arg:dict];
            }
        }];
    }
}

@end
