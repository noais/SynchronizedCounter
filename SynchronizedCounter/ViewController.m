//
//  ViewController.m
//  test
//
//  Created by David Miguel Vicente Ferreira on 11/08/16.
//  Copyright © 2016 David Miguel Vicente Ferreira. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"

NSString *const urlStr = @"http://localhost:8888/value";


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@property NSInteger magicValue;                 // value displayed (reflects the value where is already on server)
@property NSInteger pendingClicks;              // if post fails clicks goes be incrementing on this variable
@property __block BOOL isWaiting;               // flag where inform if there are some request pending

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setMagicValue:0];
    [self setPendingClicks:0];
    [self setIsWaiting:NO];

    [self getValue];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    /*  
     * After pushing the button each label in all phones with the app running are updated in real time with a counter value
     * this timer is far for the best implementation, is a beautiful method to drain the battery.
     * best way to update the values is using push notifications
     *
     **/
    
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:self
                                   selector:@selector(getValue)
                                   userInfo:nil
                                    repeats:YES];
}



- (IBAction)incrementValue:(id)sender {
    [self setPendingClicks:_pendingClicks+1];
    if (!_isWaiting) {
        [self postValue];
    }
}


-(void)postValue{
    [self setIsWaiting:YES];
    
    __block NSInteger backupValue = _pendingClicks;

    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [manager POST:urlStr parameters: @{ @"value": [NSNumber numberWithFloat:_pendingClicks]} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"success!");
        if([responseObject isKindOfClass:[NSDictionary class]]){
            NSLog(@"JSON: %@", [responseObject valueForKey:@"value"]);
            [self setIsWaiting:NO];
            _magicValue = [[responseObject valueForKey:@"value"] integerValue]; // to be improved JSON library is better indid
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.valueLabel.text = [NSString stringWithFormat:@"%ld",(long)_magicValue + _pendingClicks]; // values where are pending must to be present already in the application
            });
        }
       
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error);
        // This set are always called after to put pendingCliks to 0, in case of post failure pending clicks most be recovered
        // Post dont retry to give some time to the server only retry again when some other incremention are made.
        [self setPendingClicks:_pendingClicks + backupValue];
        [self setIsWaiting:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.valueLabel.text = [NSString stringWithFormat:@"%ld",(long)_magicValue + _pendingClicks]; // values where are pending must to be present already in the application
        });
    }];
    
    [self setPendingClicks:0];
}


-(void)getValue{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:urlStr parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        if([responseObject isKindOfClass:[NSDictionary class]]){
            NSLog(@"JSON: %@", [responseObject valueForKey:@"value"]);
            [self setIsWaiting:NO];
            _magicValue = [[responseObject valueForKey:@"value"] integerValue];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.valueLabel.text = [NSString stringWithFormat:@"%ld",(long)_magicValue + _pendingClicks]; // values where are pending must to be present already in the application
            });
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}
@end
