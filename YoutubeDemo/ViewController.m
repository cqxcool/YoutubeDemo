//
//  ViewController.m
//  YoutubeDemo
//
//  Created by Jose Chen on 16/6/29.
//  Copyright © 2016年 Jose Chen. All rights reserved.
//

#import "ViewController.h"
#import "GTMOAuth2Authentication.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLRYouTube.h"
#import "YoutubeManager.h"
#import "MBProgressHUD.h"
#import <GPUImage/GPUImageVideoCamera.h>
#import <GPUImage/GPUImageView.h>
#import <GDLiveStreaming/GDLRawDataOutput.h>

#define FRONTROW_ROOT [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]


#define GTL_USE_FRAMEWORK_IMPORTS 1

//
//#import "GTLYouTube.h"
#import "GTMSessionUploadFetcher.h"
#import "GTMSessionFetcherLogging.h"
#import "GTLRService.h"

//static NSString *const kKeychainItemName = @"YoutubeDemo Token";
//
//static NSString *clientId=@"1088267263716-2frfetr0gep957ka86od8r3r9f8nn0bv.apps.googleusercontent.com";
//static NSString *clientSecret=@"PoEzufb6s5tSEvGlwahyH_Dg";
//static NSString *scope = @"https://www.googleapis.com/auth/youtube";


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *tokenTextView;
@property (weak, nonatomic) IBOutlet UILabel *loginLabel;
@property(nonatomic,strong) GPUImageVideoCamera *camera;
@property(nonatomic,strong) GPUImageView *imageView;
@property(nonatomic,strong) GDLRawDataOutput *output;
@property(nonatomic,strong)   GTLRYouTube_LiveBroadcast *currentBroadcast;
@property(nonatomic,strong) NSTimer   *currentBroadcastTimer;
@property(nonatomic,assign) BOOL isRequesting;

@end

@implementation ViewController

//- (GTLRYouTubeService *)youTubeService {
//    static GTLRYouTubeService *service;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        service = [[GTLRYouTubeService alloc] init];
//        // Have the service object set tickets to fetch consecutive pages
//        // of the feed so we do not need to manually fetch them.
//        service.shouldFetchNextPages = YES;
//        // Have the service object set tickets to retry temporary error conditions
//        // automatically.
//        service.retryEnabled = YES;
//    });
//    return service;
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GTMOAuth2Authentication *auth = nil;
    auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                 clientID:clientId
                                                             clientSecret:clientSecret];
    
     
//    auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:@"test_move_token"
//                                                                 clientID:clientId
//                                                             clientSecret:clientSecret];
//    auth.refreshToken = @"1/Ux76xgbbEYzA39HB2On-cNq7RrrlEiutxqgDTmKW2K0";
    
    NSLog(@"tokent = %@",[[NSUserDefaults standardUserDefaults] objectForKey:@"token"]);
    NSLog(@"refresh token = %@",auth.refreshToken);
//    auth.accessToken = @"ya29.Ci8ZAynxUSjJK-XS-y6p2WObPo71oTJ1aIHMNciH_7sSDENCMGQ3gvJBV3PdLPeokQ";
//    auth.expirationDate = [NSDate dateWithTimeIntervalSinceNow:500];
//    auth.refreshToken = nil;
    
    if (auth.canAuthorize) {
        // Select the Google service segment
        self.tokenTextView.text = [auth.parameters objectForKey:@"refresh_token"];
        [YoutubeManager defaultManager].youTubeService.authorizer = auth;
        self.loginLabel.text = @"已登录";
    }
    
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)GoogleLogin:(id)sender {
    [self login];
}

- (void)login
{
    NSLog(@"Youtube 登录中......");
    SEL finishedSel = @selector(viewController:finishedWithAuth:error:);
    GTMOAuth2ViewControllerTouch *viewController;
    viewController = [GTMOAuth2ViewControllerTouch controllerWithScope:scope
                                                              clientID:clientId
                                                          clientSecret:clientSecret
                                                      keychainItemName:kKeychainItemName
                                                              delegate:self
                                                      finishedSelector:finishedSel];
//    viewController.loginDelegate = self;
    NSString *html = @"<html><body bgcolor=white><div align=center>Youtube 登录中......</div></body></html>";
    viewController.initialHTMLString = html;
    [self.navigationController pushViewController:viewController animated:YES];
}

-(void)viewController:(GTMOAuth2ViewControllerTouch *)viewController finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error{
    if (error!=nil) {
        //验证失败时，记录日志，并把弹出一个AlertView通知用户原因
        NSLog(@"Auth failed!");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:[error description] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }else{
        NSLog(@"Auth successed!");
        NSLog(@"Token: %@", [auth accessToken]);
        [[NSUserDefaults standardUserDefaults] setObject:[auth accessToken] forKey:@"token"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [YoutubeManager defaultManager].youTubeService.authorizer = auth;
        self.tokenTextView.text = [auth accessToken];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)liveNow:(id)sender
{
   MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
   hud.labelText = @"Loading";
   [hud show:YES];
    
    [[YoutubeManager defaultManager] getBroadcastList:@"persistent" identifier:nil complete:^(id result, NSError *err) {
        if (!err) {
            GTLRYouTube_LiveBroadcast *liveNowBroadcast = nil;
            for (GTLRYouTube_LiveBroadcast *broadcast in result) {
                if (broadcast.snippet.isDefaultBroadcast) {
                    liveNowBroadcast = broadcast;
                    break;
                }
            }
            
            [[YoutubeManager defaultManager] getLiveStreamList:liveNowBroadcast.contentDetails.boundStreamId
                                                      complete:^(id result, NSError *err)
            {
                [hud hide:NO];
                if (!err) {
                    GTLRYouTube_LiveStream *stream = [result objectAtIndex:0];
                    NSString *host = stream.cdn.ingestionInfo.ingestionAddress;
                    NSString *stramName = stream.cdn.ingestionInfo.streamName;
                    NSLog(@"stream = %@",stream);
                    [self startCamera:host key:stramName];
                }
            }];
        }else{
            [hud hide:YES];
        }
        
    }];
}

- (IBAction)liveEvents:(id)sender
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Loading";
    [hud show:YES];
    [self getLivestream:@"720p" complete:^(GTLRYouTube_LiveStream *stream)
    {
        __block GTLRYouTube_LiveStream *blockStream = stream;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm:ss"];
        NSString *strDate = [dateFormatter stringFromDate:[NSDate date]];
        NSString *title = [NSString stringWithFormat:@"%@-YoutubeDemo",strDate];
        [[YoutubeManager defaultManager] createBroadcast:title privacyStatus:@"public" complete:^(id result, NSError *err) {
            if (err) {
                [hud hide:NO];
                return ;
            }
            GTLRYouTube_LiveBroadcast *broadCast = result;
            [[YoutubeManager defaultManager] bindBroadcast:broadCast withStream:stream complete:^(id result, NSError *err)
            {
                [hud hide:NO];
                if (err) {
                    return ;
                }
                self.currentBroadcast = broadCast;
//                GTLRYouTube_LiveBroadcast *bindBroadCast = result;
                [self startCamera:blockStream.cdn.ingestionInfo.ingestionAddress key:blockStream.cdn.ingestionInfo.streamName];
            }];
        }];
    }];
}

- (IBAction)deleteEvents:(id)sender
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Loading";
    [hud show:YES];
    
    [[YoutubeManager defaultManager] getBroadcastList:@"event" identifier:nil complete:^(id result, NSError *err) {
        [hud hide:YES];
        if (!err) {
            for (GTLRYouTube_LiveBroadcast *broadcast in result) {
                [[YoutubeManager defaultManager] deleteBroadcast:broadcast.identifier complete:^(id result, NSError *err){
                 
                }];
            }
        }else{
            [hud hide:YES];
        }
        
    }];
}

- (void)setCurrentBroadcast:(GTLRYouTube_LiveBroadcast *)currentBroadcast
{
    _currentBroadcast = currentBroadcast;
    if (currentBroadcast) {
        if (self.currentBroadcastTimer == nil) {
            self.currentBroadcastTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkBroadcastStatus) userInfo:nil repeats:YES];
        }
    }else{
        if (self.currentBroadcastTimer) {
            [self.currentBroadcastTimer invalidate];
            self.currentBroadcastTimer = nil;
        }
    }
}

- (void)checkBroadcastStatus
{
    if ([self.currentBroadcast.status.lifeCycleStatus hasPrefix:@"live"]) {
        return;
    }
    if (self.isRequesting) {
        return;
    }
    self.isRequesting = YES;
    [[YoutubeManager defaultManager] getBroadcastList:@"event" identifier:self.currentBroadcast.identifier complete:^(id result, NSError *err) {
        if (err) {
            self.isRequesting = NO;
            return;
        }
        GTLRYouTube_LiveBroadcast *broadcast = [result objectAtIndex:0];
        NSLog(@"status = %@",broadcast.status);
        
        NSString *newStatus = nil;
        if ([broadcast.status.lifeCycleStatus isEqualToString:@"ready"]) {
            newStatus = @"testing";
        }else if ([broadcast.status.lifeCycleStatus hasPrefix:@"test"]){
            newStatus = @"live";
        }
        
        if (newStatus) {
            [[YoutubeManager defaultManager] broadcastTransition:newStatus identifier:broadcast.identifier complete:^(id result, NSError *err) {
                self.isRequesting = NO;
                if (err) {
                    return ;
                }
                self.currentBroadcast.status.lifeCycleStatus = newStatus;
            }];
        }else{
            self.isRequesting = NO;
        }
    }];
}


- (void)getLivestream:(NSString*)videoFormat
             complete:(void (^)(GTLRYouTube_LiveStream *stream))block
{
    [[YoutubeManager defaultManager] getLiveStreamList:nil complete:^(id result, NSError *err)
    {
        if (err) {
            if (block)
                block(nil);
            return ;
        }
        
        __block GTLRYouTube_LiveStream *formatStream = nil;
        for (GTLRYouTube_LiveStream *stream in result) {
            if ([stream.snippet.title isEqualToString:videoFormat]) {
                formatStream = stream;
                break;
            }
        }
        if (formatStream == nil) {
            [[YoutubeManager defaultManager] createLivestream:videoFormat
                                                  videoFormat:videoFormat
                                                     complete:^(id result, NSError *err)
            {
                if (err) {
                    if (block)
                        block(nil);
                    return ;
                }
                formatStream = result;
                if (block)
                    block(formatStream);
            }];
        }else{
            if (block)
                block(formatStream);
        }
    }];
}


- (void)startCamera:(NSString*)url key:(NSString*)key
{
    //  1. 创建视频摄像头
    self.camera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720
                                                      cameraPosition:AVCaptureDevicePositionBack];
    //  2. 设置摄像头帧率
    self.camera.frameRate = 25;
    //  3. 设置摄像头输出视频的方向
    self.camera.outputImageOrientation = UIInterfaceOrientationPortrait;
    //  4.0 创建用于展示视频的GPUImageView
    self.imageView = [[GPUImageView alloc] init];
    self.imageView.frame = self.view.bounds;
    [self.view addSubview:self.imageView];
    
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 60, 80, 60)];
    [closeButton setBackgroundColor:[UIColor greenColor]];
    [closeButton setTitle:@"Close" forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(stopCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.imageView addSubview:closeButton];
    
    //  4.1 添加GPUImageView为摄像头的的输出目标
    [self.camera addTarget:self.imageView];
    //  5. 创建原始数据输出对象
    
    self.output = [[GDLRawDataOutput alloc] initWithVideoCamera:self.camera withImageSize:CGSizeMake(720, 1280)];
    
    //  6. 添加数据输出对象为摄像头输出目标
    [self.camera addTarget:self.output];
    
    //  7.开始捕获视频
    [self.camera startCameraCapture];
    
    //  8.开始上传视频
    [ self.output startUploadStreamWithURL:url andStreamKey:key];
}

- (void)stopCamera
{
    if ([self.currentBroadcast.status.lifeCycleStatus hasPrefix:@"live"]) {
            [[YoutubeManager defaultManager] broadcastTransition:@"complete" identifier:self.currentBroadcast.identifier complete:^(id result, NSError *err) {
                if (err) {
                    return ;
                }
            }];
    }
    
    self.isRequesting = NO;
    self.currentBroadcast = nil;
    [self.output stopUploadStream];
    [self.camera stopCameraCapture];
    
    [self.imageView removeFromSuperview];
}


@end
