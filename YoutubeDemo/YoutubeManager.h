//
//  YoutubeManager.h
//  YoutubeDemo
//
//  Created by Jose Chen on 16/7/11.
//  Copyright © 2016年 Jose Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GTLRYouTube.h"
#import "GTMSessionUploadFetcher.h"
#import "GTMSessionFetcherLogging.h"
#import "GTLRService.h"

static NSString *const kKeychainItemName = @"YoutubeDemo Token";
static NSString *clientId=@"1088267263716-2frfetr0gep957ka86od8r3r9f8nn0bv.apps.googleusercontent.com";
static NSString *clientSecret=@"PoEzufb6s5tSEvGlwahyH_Dg";
static NSString *scope = @"https://www.googleapis.com/auth/youtube";
//static NSString *scope = @"https://www.googleapis.com/auth/youtube.upload https://www.googleapis.com/auth/youtube https://www.googleapis.com/auth/youtubepartner-channel-audit https://www.googleapis.com/auth/youtube.readonly";

typedef void (^YoutubeListBlock)(id result,NSError *err);

@interface YoutubeManager : NSObject

@property (nonatomic, readonly) GTLRYouTubeService *youTubeService;
@property(nonatomic,copy)   YoutubeListBlock listBlock;

+ (instancetype)defaultManager;

/**
 *  获取broadcast列表
 *
 *  @param broadcastType @“all” @"event" @"persistent"
 */
- (void)getBroadcastList:(NSString*)broadcastType
              identifier:(NSString*)identifier
                complete:(YoutubeListBlock)block;

/**
 *  创建broadcast
 *
 *  @param title   title
 *  @param privacy @"public"
 *  @param block   回调
 */
- (void)createBroadcast:(NSString*)title
          privacyStatus:(NSString*)privacy
               complete:(YoutubeListBlock)block;

/**
 *  delete broadcast
 *
 *  @param identifier
 *  @param block
 */
- (void)deleteBroadcast:(NSString*)identifier
               complete:(YoutubeListBlock)block;

/**
 *  获取liveStream列表
 *
 *  @param identifier 特定liveStram
 *  @param block      回调
 */
- (void)getLiveStreamList:(NSString*)identifier
                 complete:(YoutubeListBlock)block;

/**
 *  创建livestream
 *
 *  @param title  title
 *  @param format @"240p" @"720p"..
 *  @param block  回调
 */
- (void)createLivestream:(NSString*)title
             videoFormat:(NSString*)format
                complete:(YoutubeListBlock)block;

/**
 *  绑定stream
 *
 *  @param broadCast
 *  @param stream
 *  @param block
 */
- (void)bindBroadcast:(GTLRYouTube_LiveBroadcast*)broadCast
           withStream:(GTLRYouTube_LiveStream*)stream
             complete:(YoutubeListBlock)block;



/**
 *  Transition
 *
 *  @param status     @"testing",@"live",@"complete"..
 *  @param identifier
 *  @param block
 */
- (void)broadcastTransition:(NSString*)status
                 identifier:(NSString*)identifier
                   complete:(YoutubeListBlock)block;


#pragma mark----------------Others---------------------
- (void)fetchMYChannelList:(YoutubeListBlock)block;
@end
