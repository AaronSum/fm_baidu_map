#include "FmOverlay.h"
#define UIColorFromRGB(hexARGB) [UIColor colorWithRed:((hexARGB & 0x00FF0000) >> 16) green:((hexARGB & 0x0000FF00) >> 8) blue:(hexARGB & 0x000000FF) alpha:((hexARGB & 0xFF000000) >> 24)/255.0f]

@implementation FmPolyline{
    BMKPolylineView* _view;
    BOOL _visible;
}

@synthesize name = _name;
@synthesize layer = _layer;
@synthesize config = _config;
@synthesize mapView = _mapView;
@synthesize registrar = _registrar;

-(void)remove{
    [_mapView removeOverlay:self];
}
-(void)setVisible:(BOOL)visible{
    if ( _visible == YES ){
        if ( visible == YES ){
            return;
        }
        _visible = visible;
        [_mapView removeOverlay:self];
    }else{
        if ( visible == NO ){
            return;
        }
        _visible = visible;
        [_mapView addOverlay:self];
    }
}
// 重写此方法并返回YES是让overlay总是绘制,否则只绘制可见区域
//-(BOOL)intersectsMapRect:(BMKMapRect)mapRect{
//    return YES;
//}
-(UIView*)view{
    if ( _view ){
        return _view;
    }
    _view = [[BMKPolylineView alloc] initWithOverlay:self];
    if ( [_config objectForKey:@"color"] ){
        NSInteger c = [[_config objectForKey:@"color"] integerValue];
        _view.strokeColor =UIColorFromRGB(c);
    }
    if ( [_config objectForKey:@"width"] ){
        _view.lineWidth = [[_config objectForKey:@"width"] floatValue];
    }else{
        _view.lineWidth = 1.0;
    }
    if ( [_config objectForKey:@"dottedLine"] ){
        _view.lineDash = [[_config objectForKey:@"dottedLine"] boolValue];
    }
    _visible = YES;
    return _view;
}
@end

@implementation FmPolygon{
    BMKPolygonView* _view;
    BOOL _visible;
}

@synthesize name = _name;
@synthesize layer = _layer;
@synthesize config = _config;
@synthesize mapView = _mapView;
@synthesize registrar = _registrar;

-(void)remove{
    [_mapView removeOverlay:self];
}
-(void)setVisible:(BOOL)visible{
    if ( _visible == YES ){
        if ( visible == YES ){
            return;
        }
        _visible = visible;
        [_mapView removeOverlay:self];
    }else{
        if ( visible == NO ){
            return;
        }
        _visible = visible;
        [_mapView addOverlay:self];
    }
}
// 重写此方法并返回YES是让overlay总是绘制,否则只绘制可见区域
//-(BOOL)intersectsMapRect:(BMKMapRect)mapRect{
//    return YES;
//}
-(UIView*)view{
    if ( _view ){
        return _view;
    }
    _view = [[BMKPolygonView alloc] initWithOverlay:self];
    if ( [_config objectForKey:@"fillColor"] ){
        NSInteger c = [[_config objectForKey:@"fillColor"] integerValue];
        _view.fillColor =UIColorFromRGB(c);
    }
    if ( [_config objectForKey:@"strokeColor"] ){
        NSInteger c = [[_config objectForKey:@"strokeColor"] integerValue];
        _view.strokeColor =UIColorFromRGB(c);
    }
    if ( [_config objectForKey:@"strokeWidth"] ){
        _view.lineWidth = [[_config objectForKey:@"strokeWidth"] floatValue];
    }else{
        _view.lineWidth = 1.0;
    }
    if ( [_config objectForKey:@"dottedLine"] ){
        _view.lineDash = [[_config objectForKey:@"dottedLine"] boolValue];
    }
    _visible = YES;
    return _view;
}
@end

@implementation FmMarkerAnnotation{
    BMKAnnotationView* _view;
}

@synthesize name = _name;
@synthesize layer = _layer;
@synthesize config = _config;
@synthesize mapView = _mapView;
@synthesize registrar = _registrar;

-(UIImage*) getTextBitmap:(UIImage*) image text:(NSString*)text textSize:(float)textSize textColor:(NSInteger)textColor{
    if (image != nil && text.length > 0) {
        UIGraphicsBeginImageContext(image.size);
        CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
        [image drawInRect:rect];
        UIColor* color = textColor?UIColorFromRGB(textColor):[UIColor blackColor];
        NSMutableParagraphStyle* style = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        style.alignment = NSTextAlignmentCenter;
        UIFont* font = [UIFont systemFontOfSize:textSize?textSize:16];
        NSDictionary* dictionary = @{NSFontAttributeName:font,NSParagraphStyleAttributeName:style,NSForegroundColorAttributeName:color};
        CGSize tSize = [text sizeWithAttributes:dictionary];
        CGRect r = CGRectMake(rect.origin.x, rect.origin.y+rect.size.height/2.0-tSize.height/2.0, rect.size.width, rect.size.height);
        [text drawInRect:r withAttributes:dictionary];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return image;
}

-(UIView*)view{
    if ( _view ){
        return _view;
    }
    static NSString *pointReuseIndentifier = @"pointReuseIndentifier";
    BMKPinAnnotationView*annotationView = (BMKPinAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndentifier];
    if (annotationView == nil) {
        annotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:self reuseIdentifier:pointReuseIndentifier];
    }
    if ( [_config objectForKey:@"icon"] ){
        NSString* key = [_registrar lookupKeyForAsset:[_config objectForKey:@"icon"]];
        NSString* path = [[NSBundle mainBundle] pathForResource:key ofType:nil];
        UIImage* image =[UIImage imageWithContentsOfFile:path];
        if ( [_config objectForKey:@"text"] ){
            image = [self getTextBitmap:image
                                   text:[_config objectForKey:@"text"]
                               textSize:[[_config objectForKey:@"textSize"] floatValue]
                              textColor:[[_config objectForKey:@"textColor"] integerValue]
                     ];
        }
        double xOffset = 0;
        double yOffset = 0;
        if ( [_config objectForKey:@"anchorX"] ){
            xOffset =[[_config objectForKey:@"anchorX"] doubleValue]-0.5;
        }
        if ( [_config objectForKey:@"anchorY"] ){
            yOffset =[[_config objectForKey:@"anchorY"] doubleValue]-0.5;
        }
        double fixelW = CGImageGetWidth(image.CGImage);
        double fixelH = CGImageGetHeight(image.CGImage);
        annotationView.centerOffset =CGPointMake(xOffset * fixelW, -yOffset * fixelH);
        annotationView.image =image;
    }
    _view = annotationView;
    return _view;
}

-(void)remove{
    [_mapView removeAnnotation:self];
}
-(void)setVisible:(BOOL)visible{
    if ( _view ){
        _view.hidden = !visible;
    }
}
@end




@implementation FmLocationAnnotation{
    BMKAnnotationView* _view;
}

@synthesize name = _name;
@synthesize layer = _layer;
@synthesize config = _config;
@synthesize mapView = _mapView;
@synthesize registrar = _registrar;


-(UIView*)view{
    if ( _view ){
        return _view;
    }
    static NSString *pointReuseIndentifier = @"pointReuseIndentifier";
    BMKPinAnnotationView*annotationView = (BMKPinAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndentifier];
    if (annotationView == nil) {
        annotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:self reuseIdentifier:pointReuseIndentifier];
        annotationView.canShowCallout = NO;
    }
    
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 44)];
    bgView.backgroundColor = [UIColor whiteColor];
    
    bgView.layer.masksToBounds = YES;
    bgView.layer.cornerRadius = 4;
    bgView.layer.borderColor = [UIColor colorWithRed:0.977 green:0.332 blue:0.09 alpha:1].CGColor;
    bgView.layer.borderWidth = 0.5;
    
    [annotationView addSubview:bgView];
    
    if ( [_config objectForKey:@"locname"] ) {
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(4, 5, 75, 17)];
        label.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
        label.textAlignment = NSTextAlignmentCenter;
        label.text =[_config objectForKey:@"locname"];
        label.font = [UIFont systemFontOfSize:12];
        [bgView addSubview:label];
    }
    
    
    if ( [_config objectForKey:@"locdesc"] ) {
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(4, 22, 75, 17)];
        label.textAlignment = NSTextAlignmentCenter;
        NSAttributedString *attrStr = [[NSAttributedString alloc] initWithData:[[_config objectForKey:@"locdesc"] dataUsingEncoding:NSUnicodeStringEncoding] options:@{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType} documentAttributes:nil error:nil];
        label.attributedText = attrStr;
        label.font = [UIFont systemFontOfSize:12];
        [bgView addSubview:label];
    }
    
    
    if ( [_config objectForKey:@"icon"] ){
        NSString* key = [_registrar lookupKeyForAsset:[_config objectForKey:@"icon"]];
        NSString* path = [[NSBundle mainBundle] pathForResource:key ofType:nil];
        UIImage* image =[UIImage imageWithContentsOfFile:path];
        
        double imageWidth =image.size.width * 2 / 3.0;
        double imageHeight =image.size.height * 2 / 3.0;
        
        double fixelW = 80.0;
        double fixelH = bgView.frame.size.height + imageHeight;
        
        annotationView.centerOffset =CGPointMake(-fixelW / 2, -fixelH);
        annotationView.image = nil;
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = CGRectMake(bgView.center.x - imageWidth / 2, bgView.frame.origin.y + bgView.frame.size.height + 2, imageWidth, imageHeight);
        [annotationView addSubview:imageView];
    }
    
    _view = annotationView;
    return _view;
}

-(void)remove{
    [_mapView removeAnnotation:self];
}
-(void)setVisible:(BOOL)visible{
    if ( _view ){
        _view.hidden = !visible;
    }
}
@end



@implementation FmTextAnnotation{
    BMKAnnotationView* _view;
}

@synthesize name = _name;
@synthesize layer = _layer;
@synthesize config = _config;
@synthesize mapView = _mapView;
@synthesize registrar = _registrar;

-(UIView*)view{
    return _view;
}

-(void)remove{
    [_mapView removeAnnotation:self];
}
-(void)setVisible:(BOOL)visible{
    if ( _view ){
        [_view setHidden:!visible];
    }
}
@end

@implementation FmOverlayManager{
    NSMutableDictionary* _overlays;
}

- (instancetype)init{
    _overlays = [[NSMutableDictionary alloc] init];
    return [super init];
}

- (id)add:(NSString *)name overlay:(NSObject<FmOverlayItemBase> *)overlay {
    [_overlays setValue:overlay forKey:name];
    return  self;
}

-(BOOL)remove:(NSString*)name{
    NSObject<FmOverlayItemBase> *item =[_overlays valueForKey:name ];
    if ( !item ){
        return NO;
    }
    [item remove];
    [_overlays removeObjectForKey:name];
    return  YES;
}
-(void)removeAll{
    for (NSString* key in _overlays){
        [self remove:key];
    }
    [_overlays removeAllObjects];
}

-(BOOL)setIndex:(NSString*)name index:(int)index{
    //    FmOverlayItem* item =[_overlays valueForKey:name ];
    //    if ( !item ){
    //        return NO;
    //    }
    //    [item.overlay setIndex:index];
    return YES;
}
-(void)setIndexAll:(int)index{
    for (NSString* key in _overlays){
        [self setIndex:key index:index];
    }
}


-(BOOL)setVisible:(NSString*)name visible:(BOOL)visible{
    NSObject<FmOverlayItemBase> *item =[_overlays valueForKey:name ];
    if ( !item ){
        return NO;
    }
    [item setVisible:visible];
    return YES;
}
-(void)setVisibleAll:(BOOL)visible{
    for (NSString* key in _overlays){
        [self setVisible:key visible:visible];
    }
}
@end
