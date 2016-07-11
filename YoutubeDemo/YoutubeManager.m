//
//  YoutubeManager.m
//  YoutubeDemo
//
//  Created by Jose Chen on 16/7/11.
//  Copyright © 2016年 Jose Chen. All rights reserved.
//

#import "YoutubeManager.h"

@implementation YoutubeManager

+ (instancetype)defaultManager
{
    static YoutubeManager *gYoutubeManager = nil;
    if (gYoutubeManager == nil) {
        gYoutubeManager = [[YoutubeManager alloc] init];
    }
    return gYoutubeManager;
}

- (GTLRYouTubeService *)youTubeService {
    static GTLRYouTubeService *service;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[GTLRYouTubeService alloc] init];
//        service.APIKey = @"AIzaSyBDCCn9NWCGrRG8_LdGY4WnZVFmFNoh5cg";
//        service.APIKey = @"AIzaSyAnVJCQqClq2bM8haKfT6LzqBp-lh9nfkc";
        // Have the service object set tickets to fetch consecutive pages
        // of the feed so we do not need to manually fetch them.
        service.shouldFetchNextPages = YES;
        // Have the service object set tickets to retry temporary error conditions
        // automatically.
        service.retryEnabled = YES;
    });
    return service;
}


/**
 *  获取broadcast列表
 *
 *  @param broadcastType @“all” @"event" @"persistent"
 */
- (void)getBroadcastList:(NSString*)broadcastType
              identifier:(NSString*)identifier
                complete:(YoutubeListBlock)block
{
    GTLRYouTubeService *service = self.youTubeService;
    GTLRYouTubeQuery_LiveBroadcastsList *query =
    [GTLRYouTubeQuery_LiveBroadcastsList queryWithPart:@"id,snippet,contentDetails,status"];
    if (identifier) {
        query.identifier = identifier;
    }else{
        query.mine = YES;
    }
    query.broadcastType = broadcastType;
    [service executeQuery:query
        completionHandler:^(GTLRServiceTicket *callbackTicket,
                            GTLRYouTube_LiveBroadcastListResponse *broadcastList,
                            NSError *callbackError)
    {
            if (callbackError) {
                NSLog(@"Could not fetch video list: %@", callbackError);
            } else {
                NSLog(@"category list = %@",broadcastList);
            }
            if (block) {
                block(broadcastList.items,callbackError);
            }
        }];
}


/**
 *  创建broadcast
 *
 *  @param title   title
 *  @param privacy @"public"
 *  @param block   回调
 */
- (void)createBroadcast:(NSString*)title
          privacyStatus:(NSString*)privacy
               complete:(YoutubeListBlock)block
{
    GTLRYouTubeService *service = self.youTubeService;
    GTLRYouTube_LiveBroadcast *newBroadcast = [[GTLRYouTube_LiveBroadcast alloc] init];
    newBroadcast.kind = @"youtube#liveBroadcast";
    
    GTLRYouTube_LiveBroadcastStatus *status = [[GTLRYouTube_LiveBroadcastStatus alloc] init];
    status.privacyStatus = privacy;
    newBroadcast.status = status;
    
    GTLRYouTube_LiveBroadcastSnippet *snippet = [[GTLRYouTube_LiveBroadcastSnippet alloc] init];
    snippet.title = title;
    snippet.scheduledStartTime = [GTLRDateTime dateTimeWithDate:[NSDate date]];
    snippet.scheduledEndTime = [GTLRDateTime dateTimeWithDate:[NSDate dateWithTimeIntervalSinceNow:100000]];
    snippet.publishedAt = [GTLRDateTime dateTimeWithDate:[NSDate dateWithTimeIntervalSinceNow:30]];
    newBroadcast.snippet = snippet;
    
    GTLRYouTubeQuery_LiveBroadcastsInsert *insertQuery =  [GTLRYouTubeQuery_LiveBroadcastsInsert queryWithObject:newBroadcast part:@"snippet,status"];
    [service executeQuery:insertQuery
        completionHandler:^(GTLRServiceTicket *callbackTicket,
                            GTLRYouTube_LiveBroadcast *returnBroadcast,
                            NSError *callbackError) {
            if (callbackError) {
                NSLog(@"Could not fetch video list: %@", callbackError);
            } else {
                NSLog(@"category list = %@",returnBroadcast);
            }
            if (block) {
                block(returnBroadcast,callbackError);
            }
        }];
}

/**
 *  delete broadcast
 *
 *  @param identifier
 *  @param block
 */
- (void)deleteBroadcast:(NSString*)identifier
                complete:(YoutubeListBlock)block
{
    
    GTLRYouTubeQuery_LiveBroadcastsDelete *query = [GTLRYouTubeQuery_LiveBroadcastsDelete queryWithIdentifier:identifier];
    [self.youTubeService executeQuery:query
                    completionHandler:^(GTLRServiceTicket *callbackTicket,
                                        GTLRYouTube_LiveStream *liveStream,
                                        NSError *callbackError) {
                        if (callbackError) {
                            NSLog(@"Could not fetch video list: %@", callbackError);
                        } else {
                            NSLog(@"createstream list = %@ path = %@",liveStream,liveStream.cdn.ingestionInfo);
                        }
                        if (block) {
                            block(liveStream,callbackError);
                        }
                    }];
}


/**
 *  获取liveStream列表
 *
 *  @param identifier 特定liveStram
 *  @param block      回调
 */
- (void)getLiveStreamList:(NSString*)identifier
                 complete:(YoutubeListBlock)block
{
    GTLRYouTubeService *service = self.youTubeService;
    GTLRYouTubeQuery_LiveStreamsList *query =
    [GTLRYouTubeQuery_LiveStreamsList queryWithPart:@"id,cdn,snippet,contentDetails,status"];
//    query.mine = YES;
    if (identifier) {
        //指定查找某个stream
        query.identifier = identifier;// @"XMHHBARmvQy5toFPo8BOaQ1466995002204608"
    }else{
        query.mine = YES;
    }
    
    [service executeQuery:query
        completionHandler:^(GTLRServiceTicket *callbackTicket,
                            GTLRYouTube_LiveStreamListResponse *liveStreamList,
                            NSError *callbackError) {
            if (callbackError)
            {
                NSLog(@"Could not fetch video  list: %@", callbackError);
            } else
            {
                NSLog(@"stream list = %@",liveStreamList);
                for (GTLRYouTube_LiveStream *liveStream in liveStreamList) {
                    NSString *title = liveStream.snippet.title;
                    NSString *streamIdentifier = liveStream.identifier;
                    NSLog(@"title = %@ identifier = %@ inject=%@",title,streamIdentifier,liveStream.cdn.ingestionInfo);
                }
            }
            block(liveStreamList.items,callbackError);
        }];
}

/**
 *  创建livestream
 *
 *  @param title  title
 *  @param format @"240p" @"720p"..
 *  @param block  回调
 */
- (void)createLivestream:(NSString*)title
             videoFormat:(NSString*)format
                complete:(YoutubeListBlock)block
{
    GTLRYouTube_LiveStream *newStream = [[GTLRYouTube_LiveStream alloc] init];
    newStream.kind = @"youtube#liveStream";
    GTLRYouTube_LiveStreamSnippet *snippet = [[GTLRYouTube_LiveStreamSnippet alloc] init];
    snippet.title  = title;
    newStream.snippet = snippet;
    GTLRYouTube_CdnSettings *setting = [[GTLRYouTube_CdnSettings alloc] init];
    setting.format = format;
    setting.ingestionType = @"rtmp";
    newStream.cdn = setting;

    GTLRYouTubeQuery_LiveStreamsInsert *streamQuery =
    [GTLRYouTubeQuery_LiveStreamsInsert queryWithObject:newStream part:@"id,snippet,cdn,status"];
    [self.youTubeService executeQuery:streamQuery
        completionHandler:^(GTLRServiceTicket *callbackTicket,
                            GTLRYouTube_LiveStream *liveStream,
                            NSError *callbackError) {
            if (callbackError) {
                NSLog(@"Could not fetch video list: %@", callbackError);
            } else {
                NSLog(@"createstream list = %@ path = %@",liveStream,liveStream.cdn.ingestionInfo);
            }
            if (block) {
                block(liveStream,callbackError);
            }
        }];
}


/**
 *  绑定stream
 *
 *  @param broadCast
 *  @param stream
 *  @param block
 */
- (void)bindBroadcast:(GTLRYouTube_LiveBroadcast*)broadCast
           withStream:(GTLRYouTube_LiveStream*)stream
            complete:(YoutubeListBlock)block
{
    
    GTLRYouTubeService *service = self.youTubeService;
    
    GTLRYouTubeQuery_LiveBroadcastsBind *query = [GTLRYouTubeQuery_LiveBroadcastsBind queryWithIdentifier:broadCast.identifier
                                                                                                     part:@"id,snippet,contentDetails"];
    query.streamId = stream.identifier;
    [service executeQuery:query
        completionHandler:^(GTLRServiceTicket *callbackTicket,
                            GTLRYouTube_LiveBroadcast *returnBroadcast,
                            NSError *callbackError) {
            if (callbackError) {
                NSLog(@"Could not fetch video  list: %@", callbackError);
            } else {
                NSLog(@"broadcast list = %@ livestream=%@",returnBroadcast,stream);
            }
            if (block) {
                block(returnBroadcast,callbackError);
            }
        }];
}


/**
 *  Transition
 *
 *  @param status     @"testing",@"live",@"complete"..
 *  @param identifier
 *  @param block
 */
- (void)broadcastTransition:(NSString*)status
           identifier:(NSString*)identifier
             complete:(YoutubeListBlock)block
{
    GTLRYouTubeQuery_LiveBroadcastsTransition *query = [GTLRYouTubeQuery_LiveBroadcastsTransition queryWithBroadcastStatus:status identifier:identifier part:@"id,snippet,contentDetails,status"];
    [self.youTubeService executeQuery:query completionHandler:^(GTLRServiceTicket * _Nonnull callbackTicket,
                                                                GTLRYouTube_LiveBroadcast* returnBroadcast,
                                                                NSError * _Nullable callbackError)
     {
         if (callbackError) {
             NSLog(@"callbackError result: %@", callbackError);
         } else {
             NSLog(@"broadcast list = %@",returnBroadcast);
         }
         if (block)
             block(returnBroadcast,callbackError);
         
    }];
}


#pragma mark----------------Others---------------------
- (void)fetchMYChannelList:(YoutubeListBlock)block
{
    GTLRYouTubeService *service = self.youTubeService;
    GTLRYouTubeQuery_ChannelsList *query =
    [GTLRYouTubeQuery_ChannelsList queryWithPart:@"contentDetails"];
    query.mine = YES;
    query.maxResults = 50;
    [service executeQuery:query
                    completionHandler:^(GTLRServiceTicket *callbackTicket,
                     GTLRYouTube_ChannelListResponse *channelList,
                    NSError *callbackError)
    {
        NSLog(@"fetchmy = %@",channelList);
        if (channelList.items.count > 0) {
            GTLRYouTube_Channel *channel = channelList[0];
            NSLog(@"channel = %@",channel);
        }
        if (block) {
            block(channelList,callbackError);
        }
    }];
}



@end
