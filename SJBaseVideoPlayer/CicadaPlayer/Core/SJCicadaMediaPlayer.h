//
//  SJCicadaMediaPlayer.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJMediaPlaybackController.h"
#import <CicadaPlayerSDK/CicadaMediaInfo.h>
#import <CicadaPlayerSDK/CicadaSource.h>
#import <CicadaPlayerSDK/CicadaConfig.h>
#import <CicadaPlayerSDK/CicadaDef.h>
#import <CicadaPlayerSDK/CicadaCacheConfig.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSErrorDomain const SJCicadaMediaPlayerErrorDomain;

///
/// 内部封装了 CicadaPlayer
///
@interface SJCicadaMediaPlayer : NSObject<SJMediaPlayer>
- (instancetype)initWithSource:(__kindof CicadaSource *)source config:(nullable CicadaConfig *)config cacheConfig:(nullable CicadaCacheConfig *)cacheConfig startPosition:(NSTimeInterval)time;

@property (nonatomic) NSTimeInterval trialEndPosition;
@property (nonatomic) BOOL pauseWhenAppDidEnterBackground;
@property (nonatomic) CicadaScalingMode scalingMode;
@property (nonatomic) CicadaSeekMode seekMode;

@property (nonatomic, strong, readonly) __kindof CicadaSource *source;
@property (nonatomic, readonly) BOOL firstVideoFrameRendered;
@property (nonatomic, strong, readonly) UIView *view;
@property (nonatomic, readonly, nullable) NSArray<CicadaTrackInfo *> *trackInfos;
- (nullable CicadaTrackInfo *)currentTrackInfo:(CicadaTrackType)type;
- (void)selectTrack:(int)trackIndex accurateSeeking:(BOOL)accurateSeeking completed:(void(^)(BOOL finished))completionHandler;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

extern NSNotificationName const SJCicadaMediaPlayerOnTrackReadyNotification;
NS_ASSUME_NONNULL_END
