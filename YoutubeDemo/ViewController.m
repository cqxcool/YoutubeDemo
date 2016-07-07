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

#define GTL_USE_FRAMEWORK_IMPORTS 1

//
//#import "GTLYouTube.h"
#import "GTMSessionUploadFetcher.h"
#import "GTMSessionFetcherLogging.h"
#import "GTLRService.h"

static NSString *const kKeychainItemName = @"YoutubeDemo Token";

static NSString *clientId=@"1088267263716-2frfetr0gep957ka86od8r3r9f8nn0bv.apps.googleusercontent.com";
static NSString *clientSecret=@"PoEzufb6s5tSEvGlwahyH_Dg";
static NSString *scope = @"https://www.googleapis.com/auth/youtube";


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *tokenTextView;
@property(nonatomic,strong) NSString *token;
@property (nonatomic, readonly) GTLRYouTubeService *youTubeService;
@property (nonatomic,strong) GTMOAuth2Authentication *myAuth;
@property (nonatomic,strong) GTLRYouTube_LiveStream *myStream;
@end

@implementation ViewController

- (GTLRYouTubeService *)youTubeService {
    static GTLRYouTubeService *service;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[GTLRYouTubeService alloc] init];
        // Have the service object set tickets to fetch consecutive pages
        // of the feed so we do not need to manually fetch them.
        service.shouldFetchNextPages = YES;
        // Have the service object set tickets to retry temporary error conditions
        // automatically.
        service.retryEnabled = YES;
    });
    return service;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GTMOAuth2Authentication *auth = nil;
    auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                 clientID:clientId
                                                             clientSecret:clientSecret];
    if (auth.canAuthorize) {
        // Select the Google service segment
        self.tokenTextView.text = [auth.parameters objectForKey:@"refresh_token"];
        self.youTubeService.authorizer = auth;
        self.myAuth = auth;
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
        self.token = [auth accessToken];
        self.youTubeService.authorizer = auth;
        self.tokenTextView.text = self.token;
    }
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)fetch:(id)sender {
    [self fetchCagegory];
}
- (IBAction)fetchMy:(id)sender {
    [self fetchMyChannelList];
}

- (IBAction)liveStreamList:(id)sender {
    GTLRYouTubeService *service = self.youTubeService;
    GTLRYouTubeQuery_LiveStreamsList *query =
    [GTLRYouTubeQuery_LiveStreamsList queryWithPart:@"id,snippet,contentDetails,status"];
    query.mine = YES;
    [service executeQuery:query
        completionHandler:^(GTLRServiceTicket *callbackTicket,
                            GTLRYouTube_LiveStreamListResponse *liveStreamList,
                            NSError *callbackError) {
            if (callbackError) {
                NSLog(@"Could not fetch video category list: %@", callbackError);
            } else {
                NSLog(@"category list = %@",liveStreamList);
                for (GTLRYouTube_LiveStream *liveStream in liveStreamList) {
                    NSString *title = liveStream.snippet.title;
                    NSString *categoryID = liveStream.identifier;
                    NSLog(@"title = %@ inject=%@",title,liveStream.cdn.ingestionInfo);
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                        [self bind:broadCast];
                    });
                }
                }
        }];
}
- (IBAction)newBroadcast:(id)sender {
    GTLRYouTubeService *service = self.youTubeService;
    GTLRYouTube_LiveBroadcast *newBroadcast = [[GTLRYouTube_LiveBroadcast alloc] init];
    newBroadcast.kind = @"youtube#liveBroadcast";
    
    GTLRYouTube_LiveBroadcastStatus *status = [[GTLRYouTube_LiveBroadcastStatus alloc] init];
    status.privacyStatus = @"public";
    newBroadcast.status = status;
    
    GTLRYouTube_LiveBroadcastSnippet *snippet = [[GTLRYouTube_LiveBroadcastSnippet alloc] init];
    snippet.title = @"title";
    snippet.scheduledStartTime = [GTLRDateTime dateTimeWithDate:[NSDate date]];
    snippet.scheduledEndTime = [GTLRDateTime dateTimeWithDate:[NSDate dateWithTimeIntervalSinceNow:100000]];
    newBroadcast.snippet = snippet;
    
    GTLRYouTubeQuery_LiveBroadcastsInsert *insertQuery =  [GTLRYouTubeQuery_LiveBroadcastsInsert queryWithObject:newBroadcast part:@"snippet,status"];
    [service executeQuery:insertQuery
        completionHandler:^(GTLRServiceTicket *callbackTicket,
                            GTLRYouTube_LiveBroadcast *returnBroadcast,
                            NSError *callbackError) {
            if (callbackError) {
                NSLog(@"Could not fetch video category list: %@", callbackError);
            } else {
                NSLog(@"category list = %@",returnBroadcast);
                [self bind:returnBroadcast];
            }
        }];
    
}

- (IBAction)LiveBroadList:(id)sender {
    GTLRYouTubeService *service = self.youTubeService;
    GTLRYouTubeQuery_LiveBroadcastsList *query =
    [GTLRYouTubeQuery_LiveBroadcastsList queryWithPart:@"id,snippet,contentDetails,status"];
    query.mine = YES;
    query.broadcastType = @"persistent";
    [service executeQuery:query
        completionHandler:^(GTLRServiceTicket *callbackTicket,
                            GTLRYouTube_LiveBroadcastListResponse *categoryList,
                            NSError *callbackError) {
            if (callbackError) {
                NSLog(@"Could not fetch video category list: %@", callbackError);
            } else {
                NSLog(@"category list = %@",categoryList);
                for (GTLRYouTube_LiveBroadcast *broadCast in categoryList) {
                    NSString *title = broadCast.snippet.title;
                    NSString *categoryID = broadCast.identifier;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self bind:broadCast];
                      //  [self insert:broadCast];
                    });
                }
            }
        }];
}


- (void)insert:(GTLRYouTube_LiveBroadcast*)broadCast
{
    GTLRYouTubeService *service = self.youTubeService;
    GTLRYouTubeQuery_LiveBroadcastsInsert *query =
    [GTLRYouTubeQuery_LiveBroadcastsInsert queryWithObject:broadCast part:@"snippet,contentDetails,status"];
    [service executeQuery:query
        completionHandler:^(GTLRServiceTicket *callbackTicket,
                            GTLRYouTube_LiveBroadcast *insertBroadcast,
                            NSError *callbackError) {
            if (callbackError) {
                NSLog(@"Could not fetch video category list: %@", callbackError);
            } else {
                [self bind:insertBroadcast];
            }
        }];
}


- (void)bind:(GTLRYouTube_LiveBroadcast*)broadCast
{
    
    GTLRYouTubeService *service = self.youTubeService;
    
    GTLRYouTube_LiveStream *newStream = [[GTLRYouTube_LiveStream alloc] init];
    newStream.kind = @"youtube#liveStream";
    GTLRYouTube_LiveStreamSnippet *snippet = [[GTLRYouTube_LiveStreamSnippet alloc] init];
    snippet.title  = @"titile";
    newStream.snippet = snippet;
    GTLRYouTube_CdnSettings *setting = [[GTLRYouTube_CdnSettings alloc] init];
    setting.format = @"240p";
    setting.ingestionType = @"rtmp";
    newStream.cdn = setting;
    
    
    GTLRYouTubeQuery_LiveStreamsInsert *streamQuery =
    [GTLRYouTubeQuery_LiveStreamsInsert queryWithObject:newStream part:@"id,snippet,cdn,status"];
    [service executeQuery:streamQuery
        completionHandler:^(GTLRServiceTicket *callbackTicket,
                            GTLRYouTube_LiveStream *liveStream,
                            NSError *callbackError) {
            if (callbackError) {
                NSLog(@"Could not fetch video category list: %@", callbackError);
            } else {
                NSLog(@"liveStream list = %@ path = %@",liveStream,liveStream.cdn.ingestionInfo);
                broadCast.contentDetails.boundStreamId = liveStream.identifier;
                self.myStream = liveStream;
                GTLRYouTubeQuery_LiveBroadcastsBind *query =
                [GTLRYouTubeQuery_LiveBroadcastsBind queryWithIdentifier:broadCast.identifier part:@"id,snippet,contentDetails"];
                query.streamId = liveStream.identifier;
                [service executeQuery:query
                    completionHandler:^(GTLRServiceTicket *callbackTicket,
                                        GTLRYouTube_LiveBroadcast *returnBroadcast,
                                        NSError *callbackError) {
                        if (callbackError) {
                            NSLog(@"Could not fetch video category list: %@", callbackError);
                        } else {
                            NSLog(@"category list = %@ livestream=%@",returnBroadcast,self.myStream);
                            self.myStream;
                        }
                    }];

            }
        }];
    
    

    
}

- (void)fetchCagegory {
    GTLRYouTubeService *service = self.youTubeService;
    
    GTLRYouTubeQuery_VideoCategoriesList *query =
    [GTLRYouTubeQuery_VideoCategoriesList queryWithPart:@"snippet,id"];
    query.regionCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    
    [service executeQuery:query
        completionHandler:^(GTLRServiceTicket *callbackTicket,
                            GTLRYouTube_VideoCategoryListResponse *categoryList,
                            NSError *callbackError) {
            if (callbackError) {
                NSLog(@"Could not fetch video category list: %@", callbackError);
            } else {
                NSLog(@"category list = %@",categoryList);
                for (GTLRYouTube_VideoCategory *category in categoryList) {
                    NSString *title = category.snippet.title;
                    NSString *categoryID = category.identifier;

                }
            }
        }];
}

- (void)fetchMyChannelList {
    GTLRYouTubeService *service = self.youTubeService;
    GTLRYouTubeQuery_ChannelsList *query =
    [GTLRYouTubeQuery_ChannelsList queryWithPart:@"contentDetails"];
    query.mine = YES;
    
    // maxResults specifies the number of results per page.  Since we earlier
    // specified shouldFetchNextPages=YES and this query fetches an object
    // class derived from GTLRCollectionObject, all results should be fetched,
    // though specifying a larger maxResults will reduce the number of fetches
    // needed to retrieve all pages.
    query.maxResults = 50;
    
    // We can specify the fields we want here to reduce the network
    // bandwidth and memory needed for the fetched collection.
    //
    // For example, leave query.fields as nil during development.
    // When ready to test and optimize your app, specify just the fields needed.
    // For example, this sample app might use
    //
    // query.fields = @"kind,etag,items(id,etag,kind,contentDetails)";
    
    GTLRServiceTicket *_channelListTicket = [service executeQuery:query
                             completionHandler:^(GTLRServiceTicket *callbackTicket,
                                                 GTLRYouTube_ChannelListResponse *channelList,
                                                 NSError *callbackError) {
                                 // Callback
                                 
                                 // The contentDetails of the response has the playlists available for
                                 // "my channel".
                                 NSLog(@"fetchmy = %@",channelList);
                                 if (channelList.items.count > 0) {
                                     GTLRYouTube_Channel *channel = channelList[0];
                                     NSLog(@"channel = %@",channel);
                                 }
        
                             }];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)featch:(id)sender {
}
@end
