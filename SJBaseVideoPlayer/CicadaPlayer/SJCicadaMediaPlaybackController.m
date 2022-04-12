//
//  SJCicadaMediaPlaybackController.m
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJCicadaMediaPlaybackController.h"
#import "SJCicadaMediaPlayer.h"
#import "SJCicadaMediaPlayerLayerView.h"
#import "SJVideoPlayerURLAsset+SJCicadaMediaPlaybackAdd.h"

#if __has_include(<SJUIKit/SJRunLoopTaskQueue.h>)
#import <SJUIKit/SJRunLoopTaskQueue.h>
#else
#import "SJRunLoopTaskQueue.h"
#endif

NS_ASSUME_NONNULL_BEGIN
@interface SJCicadaMediaPlaybackController ()
@property (nonatomic, strong, nullable) SJVideoPlayerURLAsset *avpTrackMedia;
@end

@implementation SJCicadaMediaPlaybackController
@dynamic currentPlayer;
- (instancetype)init {
    self = [super init];
    if ( self ) {
        _seekMode = CICADA_SEEKMODE_INACCURATE;
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_onTrackReadyWithNote:) name:SJCicadaMediaPlayerOnTrackReadyNotification object:nil];
    }
    return self;
}

- (void)playerWithMedia:(SJVideoPlayerURLAsset *)media completionHandler:(void (^)(id<SJMediaPlayer> _Nullable))completionHandler {
    if ( media.source != nil ) {
        __weak typeof(self) _self = self;
        SJRunLoopTaskQueue.main.enqueue(^{
            __strong typeof(_self) self = _self;
            if ( !self ) return;
            SJCicadaMediaPlayer *player = [SJCicadaMediaPlayer.alloc initWithSource:media.source config:media.avpConfig cacheConfig:media.avpCacheConfig startPosition:media.startPosition];
            player.seekMode = self.seekMode;
            player.pauseWhenAppDidEnterBackground = self.pauseWhenAppDidEnterBackground;
            if ( completionHandler ) completionHandler(player);
        });
    }
}

- (UIView<SJMediaPlayerView> *)playerViewWithPlayer:(id<SJMediaPlayer>)player {
    return [SJCicadaMediaPlayerLayerView.alloc initWithPlayer:player];
}

- (void)setPauseWhenAppDidEnterBackground:(BOOL)pauseWhenAppDidEnterBackground {
    [super setPauseWhenAppDidEnterBackground:pauseWhenAppDidEnterBackground];
}

- (void)setSeekMode:(CicadaSeekMode)seekMode {
    _seekMode = seekMode;
    self.currentPlayer.seekMode = seekMode;
}

#pragma mark -

- (void)setMinBufferedDuration:(NSTimeInterval)minBufferedDuration {
#ifdef DEBUG
    NSLog(@"%d \t %s \t 未实现该方法!", (int)__LINE__, __func__);
#endif
}

- (NSTimeInterval)durationWatched {
#ifdef DEBUG
    NSLog(@"%d \t %s \t 未实现该方法!", (int)__LINE__, __func__);
#endif
    return 0;
}

- (SJPlaybackType)playbackType {
#ifdef DEBUG
    NSLog(@"%d \t %s \t 未实现该方法!", (int)__LINE__, __func__);
#endif
    return SJPlaybackTypeUnknown;
}

#pragma mark - mark

- (void)_onTrackReadyWithNote:(NSNotification *)note {
    if ( note.object == self.currentPlayer ) {
        if ( self.onTrackReadyExeBlock ) self.onTrackReadyExeBlock(self);
    }
}

- (void)switchVideoDefinition:(SJVideoPlayerURLAsset *)media {
    CicadaTrackInfo *trackInfo = media.avpTrackInfo;
    if ( trackInfo == nil ) {
        [super switchVideoDefinition:media];
        return;
    }
    
    self.avpTrackMedia = media;
    [self _avp_reportDefinitionSwitchStatusWithMedia:media status:SJDefinitionSwitchStatusUnknown];
    [self _avp_reportDefinitionSwitchStatusWithMedia:media status:SJDefinitionSwitchStatusSwitching];
    __weak typeof(self) _self = self;
    [self.currentPlayer selectTrack:trackInfo.trackIndex accurateSeeking:_seekMode == CICADA_SEEKMODE_ACCURATE ? YES : NO completed:^(BOOL finished) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( media != self.avpTrackMedia ) return;
        if ( !finished ) {
            [self _avp_reportDefinitionSwitchStatusWithMedia:media status:SJDefinitionSwitchStatusFailed];
            return;
        }
        [self replaceMediaForDefinitionMedia:media];
        [self _avp_reportDefinitionSwitchStatusWithMedia:media status:SJDefinitionSwitchStatusFinished];
    }];
}

- (void)_avp_reportDefinitionSwitchStatusWithMedia:(id<SJMediaModelProtocol>)media status:(SJDefinitionSwitchStatus)status {
    if ( [self.delegate respondsToSelector:@selector(playbackController:switchingDefinitionStatusDidChange:media:)] ) {
        [self.delegate playbackController:self switchingDefinitionStatusDidChange:status media:media];
    }

#ifdef DEBUG
    char *str = nil;
    switch ( status ) {
        case SJDefinitionSwitchStatusUnknown:
            str = "Unknown";
            break;
        case SJDefinitionSwitchStatusSwitching:
            str = "Switching";
            break;
        case SJDefinitionSwitchStatusFinished:
            str = "Finished";
            break;
        case SJDefinitionSwitchStatusFailed:
            str = "Failed";
            break;
    }
    printf("SJCicadaMediaPlaybackController<%p>.switchStatus = %s\n", self, str);
#endif
}

@end
NS_ASSUME_NONNULL_END
