//
//  ViewController.m
//  Map
//
//  Created by m dychko on 1/12/17.
//  Copyright © 2017 Mariya Dychko. All rights reserved.
//

#import "ViewController.h"


@interface ViewController () <MKMapViewDelegate, CLLocationManagerDelegate>
@property CLLocationManager *location;
@property CLLocationCoordinate2D destinationCoords;
@property MKRoute *currentRoute;
@property MKPolyline *routeOverlay;
@property BOOL walk;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.location = [[CLLocationManager alloc]init];
    self.location.delegate = self;
    self.location.desiredAccuracy=kCLLocationAccuracyBest;
    self.location.distanceFilter = kCLLocationAccuracyBestForNavigation;//constant update of device location
    [self.location requestAlwaysAuthorization];
    [self.location startUpdatingLocation];
    self.walk = NO;
    
    UIGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressToGetLocation:)];
    
    [self.mapView addGestureRecognizer:longPress];
    self.mapView.showsUserLocation = YES;
    self.mapView.mapType = MKMapTypeHybrid;
    self.mapView.delegate = self;
}

- (void)destanitionInfo {
    MKDirectionsRequest *directionsRequest = [MKDirectionsRequest new];
    MKMapItem *source = [MKMapItem mapItemForCurrentLocation];
    MKPlacemark *destinationPlacemark = [[MKPlacemark alloc] initWithCoordinate:self.destinationCoords addressDictionary:nil];
    MKMapItem *destination = [[MKMapItem alloc] initWithPlacemark:destinationPlacemark];
    // Set the source and destination on the request
    [directionsRequest setSource:source];
    [directionsRequest setDestination:destination];
    MKDirections *directions = [[MKDirections alloc] initWithRequest:directionsRequest];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        // Now handle the result
        if (error) {
            NSLog(@"There was an error getting your directions");
            return;
        }
        // So there wasn't an error - let's plot those routes
        for (MKRoute *route in response.routes) {
            if (route.transportType == MKDirectionsTransportTypeWalking) {
                self.walk = YES;
            }
            _currentRoute = [response.routes firstObject];
            [self plotRouteOnMap:_currentRoute];
        }
    }];
}

- (void)plotRouteOnMap:(MKRoute *)route
{
    if(_routeOverlay) {
        [self.mapView removeOverlay:_routeOverlay];
    }
    // Update the ivar
    _routeOverlay = route.polyline;
    // Add it to the map
    [self.mapView addOverlay:_routeOverlay];
}

- (void)longpressToGetLocation:(UIGestureRecognizer *)gestureRecognizer

{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D location =
    [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    self.destinationCoords = location;
    [self  destanitionInfo];
    NSLog(@"Location found from Map: %f %f",location.latitude,location.longitude);
    
}

- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: {
            NSLog(@"User still thinking..");
        } break;
        case kCLAuthorizationStatusDenied: {
            NSLog(@"User hates you");
        } break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways: {
            [self.location startUpdatingLocation]; //Will update location immediately
        } break;
        default:
            break;
    }
}
- (void)mapView:(MKMapView *)aMapView didUpdateUserLocation:(MKUserLocation *)aUserLocation {
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.005;
    span.longitudeDelta = 0.005;
    CLLocationCoordinate2D location;
    location.latitude = aUserLocation.coordinate.latitude;
    location.longitude = aUserLocation.coordinate.longitude;
    region.span = span;
    region.center = location;
    [aMapView setRegion:region animated:YES];
    [self destanitionInfo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay
{
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    if (self.walk == YES) {
            renderer.strokeColor = [UIColor greenColor];
    } else {
            renderer.strokeColor = [UIColor redColor];
    }
    renderer.lineWidth = 4.0;
    return  renderer;
}




@end
