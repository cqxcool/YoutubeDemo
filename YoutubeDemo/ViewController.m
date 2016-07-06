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
    [self fetchPublicPlaylistWithID:@"news"];
}
- (IBAction)fetchMy:(id)sender {
    [self fetchMyChannelList];
}

- (void)fetchPublicPlaylistWithID:(NSString *)playlistID {
    // Create a service for executing queries. For best performance, reuse
    // the same service instance throughout the app.
    //
    // Some of the service's properties may be set on a per-query basis
    // via the query's executionParameters property.
    GTLRYouTubeService *service = [[GTLRYouTubeService alloc] init];
    
    // Services which do not require user authentication may need an API key
    // from the Google Developers Console
    service.APIKey = @"AIzaSyAnVJCQqClq2bM8haKfT6LzqBp-lh9nfkc";
//    service.authorizer = service.authorizer
    
    // APIs which retrieve a collection of items may need to fetch
    // multiple pages. The service can optionally make multiple requests
    // to fetch all pages. The page size can be set in most APIs with the
    // query parameter maxResults.
    service.shouldFetchNextPages = YES;
    
    // The library can retry common networking errors. The retry criteria
    // may be customized by setting the service's retryBlock property.
    service.retryEnabled = YES;
    
    // Each API method has a unique class.  The required properties
    // of the API method are the parameters of the constructor.
    // Optional properties of the API method are properties of the
    // class.
    
    // The YouTube API requires a "part" parameter for each query.
    // The playlist ID an an optional property of the method.
    GTLRYouTubeQuery_PlaylistItemsList *query =
    [GTLRYouTubeQuery_PlaylistItemsList queryWithPart:@"snippet"];
    query.playlistId = playlistID;
    
    // A ticket is returned to let the app monitor or cancel query execution.
    GTLRServiceTicket *ticket =
    [service executeQuery:query
        completionHandler:^(GTLRServiceTicket *callbackTicket,
                            GTLRYouTube_PlaylistItemListResponse *playlistItemList,
                            NSError *callbackError) {
            // This callback block is run when the fetch completes.
            if (callbackError != nil) {
                NSLog(@"Fetch failed: %@", callbackError);
            } else {
                // The error is nil, so the fetch succeeded.
                //
                // GTLRYouTube_PlaylistItemListResponse derives from
                // GTLRCollectionObject, so it supports iteration of
                // items and subscript access to items.
                for (GTLRYouTube_PlaylistItem *item in playlistItemList) {
                    // Print the name of each playlist item.
                    NSLog(@"%@", item.snippet.title);
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
