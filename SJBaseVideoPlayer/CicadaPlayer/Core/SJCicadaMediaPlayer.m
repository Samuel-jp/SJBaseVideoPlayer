//
//  SJCicadaMediaPlayer.m
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJCicadaMediaPlayer.h"
#import <CicadaPlayerSDK/CicadaPlayerSDK.h>

NS_ASSUME_NONNULL_BEGIN
NSErrorDomain const SJCicadaMediaPlayerErrorDomain = @"SJCicadaMediaPlayerErrorDomain";

@interface SJCicadaMediaPlayerDelegateProxy : NSProxy
+ (instancetype)weakProxyWithTarget:(id)target;

@property (nonatomic, weak, nullable) id target;
@end

@implementation SJCicadaMediaPlayerDelegateProxy
+ (instancetype)weakProxyWithTarget:(id)target {
    SJCicadaMediaPlayerDelegateProxy *proxy = [SJCicadaMediaPlayerDelegateProxy alloc];
    proxy.target = target;
    return proxy;
}

- (id)forwardingTargetForSelector:(SEL)selector {
    return _target;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    void *null = NULL;
    [invocation setReturnValue:&null];
}

- (nullable NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_target respondsToSelector:aSelector];
}

- (BOOL)isEqual:(id)object {
    return [_target isEqual:object];
}

- (NSUInteger)hash {
    return [_target hash];
}

- (Class)superclass {
    return [_target superclass];
}

- (Class)class {
    return [_target class];
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [_target isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
    return [_target isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [_target conformsToProtocol:aProtocol];
}

- (BOOL)isProxy {
    return YES;
}

- (NSString *)description {
    return [_target description];
}

- (NSString *)debugDescription {
    return [_target debugDescription];
}
@end


@interface SJCicadaMediaPlayer ()<CicadaDelegate>
@property (nonatomic, strong) SJCicadaMediaPlayerDelegateProxy *delegateProxy;
@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic) BOOL isPlaybackFinished;///< 播放结束
@property (nonatomic, nullable) SJFinishedReason finishedReason;    ///< 播放结束的reason
@property (nonatomic) BOOL firstVideoFrameRendered;
@property (nonatomic, copy, nullable) void(^seekCompletionHandler)(BOOL);
@property (nonatomic, copy, nullable) void(^selectTrackCompletionHandler)(BOOL);
@property (nonatomic) NSTimeInterval startPosition;
@property (nonatomic) BOOL needsSeekToStartPosition;
@property (nonatomic, nullable) SJWaitingReason reasonForWaitingToPlay;
@property (nonatomic) SJPlaybackTimeControlStatus timeControlStatus;
@property (nonatomic) SJSeekingInfo seekingInfo;
@property (nonatomic) SJAssetStatus assetStatus;
@property (nonatomic) CGSize presentationSize;

@property (nonatomic, strong, nullable) CicadaPlayer *player;
@property (nonatomic) CicadaStatus playerStatus;
@property (nonatomic) CicadaEventType eventType;

@property (nonatomic) NSTimeInterval currentTime;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSTimeInterval playableDuration;

@property (nonatomic, readonly) BOOL isPlayedToTrialEndPosition;
@end

@implementation SJCicadaMediaPlayer
@synthesize pauseWhenAppDidEnterBackground = _pauseWhenAppDidEnterBackground;
@synthesize playableDuration = _playableDuration;
@synthesize isPlayed = _isPlayed;
@synthesize isReplayed = _isReplayed;
@synthesize rate = _rate;
@synthesize volume = _volume;
@synthesize muted = _muted;

- (instancetype)initWithSource:(__kindof CicadaSource *)source config:(nullable CicadaConfig *)config cacheConfig:(nullable CicadaCacheConfig *)cacheConfig startPosition:(NSTimeInterval)time {
    self = [super init];
    if ( self ) {
        _source = source;
        _startPosition = time;
        _assetStatus = SJAssetStatusPreparing;
        _delegateProxy = [SJCicadaMediaPlayerDelegateProxy weakProxyWithTarget:self];
        _player = CicadaPlayer.alloc.init;
        _player.enableLog = NO;
        _player.delegate = (id)_delegateProxy;
        _player.playerView = UIView.new;
        _pauseWhenAppDidEnterBackground = YES;
        _seekMode = CICADA_SEEKMODE_INACCURATE;
        _needsSeekToStartPosition = time != 0;
        
        if ( config != nil )
            [_player setConfig:config];
        
        if ( cacheConfig != nil )
            [_player setCacheConfig:cacheConfig];
        
        if      ( [source isKindOfClass:CicadaUrlSource.class] ) {
            [_player setUrlSource:source];
        }
//        else if ( [source isKindOfClass:CicadaVidStsSource.class] ) {
//            [_player setStsSource:source];
//        }
//        else if ( [source isKindOfClass:CicadaVidMpsSource.class] ) {
//            [_player setMpsSource:source];
//        }
//        else if ( [source isKindOfClass:CicadaVidAuthSource.class] ) {
//            [_player setAuthSource:source];
//        }
        
        [_player prepare];

        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%d \t %s", (int)__LINE__, __func__);
#endif
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_player destroy];
}

- (UIView *)view {
    return self.player.playerView;
}

- (nullable NSArray<CicadaTrackInfo *> *)trackInfos {
    return self.player.getMediaInfo.tracks;
}

- (nullable CicadaTrackInfo *)currentTrackInfo:(CicadaTrackType)type {
    return [self.player getCurrentTrack:type];
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^_Nullable)(BOOL))completionHandler {
    if ( self.assetStatus != SJAssetStatusReadyToPlay ) {
        if ( completionHandler ) completionHandler(NO);
        return;
    }
    
    if ( self.seekingInfo.isSeeking ) {
        [self _didEndSeeking:NO];
    }
    
    time = [self _adjustSeekTimeIfNeeded:time];
    
    _seekCompletionHandler = completionHandler;
    [self _willSeeking:time];
    [_player seekToTime:CMTimeGetSeconds(time) * 1000 seekMode:_seekMode];
}

- (void)play {
    _isPlayed = YES;
    
    if ( self.isPlaybackFinished ) {
        [self replay];
    }
    else {
        self.reasonForWaitingToPlay = SJWaitingWhileEvaluatingBufferingRateReason;
        self.timeControlStatus = SJPlaybackTimeControlStatusWaitingToPlay;

        [_player start];
    }
}
- (void)pause {
    self.reasonForWaitingToPlay = nil;
    self.timeControlStatus = SJPlaybackTimeControlStatusPaused;

    [_player pause];
}

- (void)replay {
    _isReplayed = YES;
    __weak typeof(self) _self = self;
    [self seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( self.playerStatus != CicadaStatusStarted ) [self play];
        [self _toEvaluating];
        [self _postNotification:SJMediaPlayerDidReplayNotification];
    }];
}
- (void)report {
    [self _postNotification:SJMediaPlayerAssetStatusDidChangeNotification];
    [self _postNotification:SJMediaPlayerTimeControlStatusDidChangeNotification];
    [self _postNotification:SJMediaPlayerDurationDidChangeNotification];
    [self _postNotification:SJMediaPlayerPlayableDurationDidChangeNotification];

}

- (nullable UIImage *)screenshot {
    return nil;
}

- (nullable NSError *)error {
    return _playerStatus == CicadaStatusError ? _error : nil;
}

- (void)selectTrack:(int)trackIndex accurateSeeking:(BOOL)accurateSeeking completed:(void(^)(BOOL finished))completionHandler {
//    [_player selectTrack:trackIndex accurate:accurateSeeking];
    [_player selectTrack:trackIndex];
    _selectTrackCompletionHandler = completionHandler;
}

#pragma mark -

-(void)onPlayerEvent:(CicadaPlayer *)player eventType:(CicadaEventType)eventType {
#ifdef SJDEBUG
    __auto_type toString = ^NSString *(CicadaEventType event) {
        switch ( event ) {
            case CicadaEventPrepareDone:
                return @"CicadaEventPrepareDone";
            case CicadaEventAutoPlayStart:
                return @"CicadaEventAutoPlayStart";
            case CicadaEventFirstRenderedStart:
                return @"CicadaEventFirstRenderedStart";
            case CicadaEventCompletion:
                return @"CicadaEventCompletion";
            case CicadaEventLoadingStart:
                return @"CicadaEventLoadingStart";
            case CicadaEventLoadingEnd:
                return @"CicadaEventLoadingEnd";
            case CicadaEventSeekEnd:
                return @"CicadaEventSeekEnd";
            case CicadaEventLoopingStart:
                return @"CicadaEventLoopingStart";
        }
    };
    
    NSLog(@"eventType: %@", toString(eventType));
#endif
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.eventType = eventType;
        [self _toEvaluating];
    });
}

- (void)onError:(CicadaPlayer *)player errorModel:(CicadaErrorModel *)errorModel {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.error = [NSError errorWithDomain:SJCicadaMediaPlayerErrorDomain code:errorModel.code userInfo:@{
            @"error" : errorModel ?: @""
        }];
        self.playerStatus = CicadaStatusError;
        [self _toEvaluating];
    });
}

- (void)onVideoSizeChanged:(CicadaPlayer *)player width:(int)width height:(int)height rotation:(int)rotation {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.presentationSize = CGSizeMake(width, height);
    });
}

- (void)onCurrentPositionUpdate:(CicadaPlayer *)player position:(int64_t)position {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval time = 1.0 * position / 1000;
        self.currentTime = time;
        if ( self.isPlayedToTrialEndPosition ) {
            [self _didPlayToTrialEndPosition];
        }
    });
}

- (void)onBufferedPositionUpdate:(CicadaPlayer *)player position:(int64_t)position {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval time = 1.0 * position / 1000;
        self.playableDuration = time;
    });
}

- (void)onPlayerStatusChanged:(CicadaPlayer *)player oldStatus:(CicadaStatus)oldStatus newStatus:(CicadaStatus)newStatus {
    if ( newStatus == CicadaStatusError) {
        return;
    }
    
#ifdef SJDEBUG
    __auto_type toString = ^NSString *(CicadaStatus status) {
        switch ( status ) {
            case CicadaStatusIdle:
                return @"CicadaStatusIdle";
            case CicadaStatusInitialzed:
                return @"CicadaStatusInitialzed";
            case CicadaStatusPrepared:
                return @"CicadaStatusPrepared";
            case CicadaStatusStarted:
                return @"CicadaStatusStarted";
            case CicadaStatusPaused:
                return @"CicadaStatusPaused";
            case CicadaStatusStopped:
                return @"CicadaStatusStopped";
            case CicadaStatusCompletion:
                return @"CicadaStatusCompletion";
            case CicadaStatusError:
                return @"CicadaStatusError";
        }
    };
    
    NSLog(@"oldStatus: %@ \t newStatus: %@", toString(oldStatus), toString(newStatus));
#endif

    dispatch_async(dispatch_get_main_queue(), ^{
        self.playerStatus = newStatus;
        [self _toEvaluating];
    });
}

- (void)onTrackReady:(CicadaPlayer *)player info:(NSArray<CicadaTrackInfo *> *)info {
    [self _postNotification:SJCicadaMediaPlayerOnTrackReadyNotification];
}

- (void)onTrackChanged:(CicadaPlayer *)player info:(CicadaTrackInfo *)info {
    if ( _selectTrackCompletionHandler != nil ) {
        _selectTrackCompletionHandler(YES);
        _selectTrackCompletionHandler = nil;
    }
}

#pragma mark -

- (void)_postNotification:(NSNotificationName)name {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:name object:self];
    });
}

- (void)_willSeeking:(CMTime)time {
    self.isPlaybackFinished = NO;
    _seekingInfo.time = time;
    _seekingInfo.isSeeking = YES;
}

- (void)_didEndSeeking:(BOOL)finished {
    _seekingInfo.time = kCMTimeZero;
    _seekingInfo.isSeeking = NO;
    if ( _seekCompletionHandler ) _seekCompletionHandler(finished);
    _seekCompletionHandler = nil;
}

- (void)_toEvaluating {
    SJAssetStatus status = self.assetStatus;
    if ( self.playerStatus == CicadaStatusPrepared ) {
        status = SJAssetStatusReadyToPlay;
    }
    else if ( self.playerStatus == CicadaStatusError ) {
        status = SJAssetStatusFailed;
    }
    
    if ( status != self.assetStatus ) {
        self.assetStatus = status;
        
        if ( _selectTrackCompletionHandler != nil ) {
            _selectTrackCompletionHandler(false);
            _selectTrackCompletionHandler = nil;
        }
        
        if ( status == SJAssetStatusReadyToPlay ) {
            if ( self.needsSeekToStartPosition ) {
                self.needsSeekToStartPosition = NO;
                [self seekToTime:CMTimeMakeWithSeconds(self.startPosition, NSEC_PER_SEC) completionHandler:nil];
            }
        }
    }
    
    if ( status == SJAssetStatusReadyToPlay && self.duration == 0 ) {
        self.duration = self.player.duration * 1.0 / 1000;
    }
    
    if ( status == SJAssetStatusFailed )
        return;
    
    if ( self.eventType == CicadaEventSeekEnd && self.seekingInfo.isSeeking ) {
        [self _didEndSeeking:YES];
    }
    else if ( self.isPlayedToTrialEndPosition ) {
        [self _didPlayToTrialEndPosition];
        return;
    }
    else if ( self.playerStatus == CicadaStatusCompletion ) {
        [self _didPlayToEndPositoion];
        return;
    }
    
    if ( self.eventType == CicadaEventFirstRenderedStart ) {
        self.firstVideoFrameRendered = YES;
    }
    
    if ( self.timeControlStatus != SJPlaybackTimeControlStatusPaused ) {
        SJPlaybackTimeControlStatus status = self.timeControlStatus;
        SJWaitingReason _Nullable reason = self.reasonForWaitingToPlay;
        if ( self.eventType == CicadaEventLoadingStart ) {
            reason = SJWaitingToMinimizeStallsReason;
            status = SJPlaybackTimeControlStatusWaitingToPlay;
        }
        else if ( self.eventType == CicadaEventLoadingEnd ) {
            reason = nil;
            status = SJPlaybackTimeControlStatusPlaying;
        }
        
        if ( status != self.timeControlStatus || reason != self.reasonForWaitingToPlay ) {
            self.reasonForWaitingToPlay = reason;
            self.timeControlStatus = status;
        }
    }
}

#pragma mark -

- (void)setAssetStatus:(SJAssetStatus)assetStatus {
    _assetStatus = assetStatus;

#ifdef SJDEBUG
    switch ( assetStatus ) {
        case SJAssetStatusUnknown:
            printf("SJCicadaMediaPlayer.assetStatus.Unknown\n");
            break;
        case SJAssetStatusPreparing:
            printf("SJCicadaMediaPlayer.assetStatus.Preparing\n");
            break;
        case SJAssetStatusReadyToPlay:
            printf("SJCicadaMediaPlayer.assetStatus.ReadyToPlay\n");
            break;
        case SJAssetStatusFailed:
            printf("SJCicadaMediaPlayer.assetStatus.Failed\n");
            break;
    }
#endif
    
    [self _postNotification:SJMediaPlayerAssetStatusDidChangeNotification];
}

- (void)setTimeControlStatus:(SJPlaybackTimeControlStatus)timeControlStatus {
    _timeControlStatus = timeControlStatus;

#ifdef SJDEBUG
    switch ( timeControlStatus ) {
        case SJPlaybackTimeControlStatusPaused:
            printf("SJCicadaMediaPlayer.timeControlStatus.Pause\n");
            break;
        case SJPlaybackTimeControlStatusWaitingToPlay:
            printf("SJCicadaMediaPlayer.timeControlStatus.WaitingToPlay.reason(%s)\n", _reasonForWaitingToPlay.UTF8String);
            break;
        case SJPlaybackTimeControlStatusPlaying:
            printf("SJCicadaMediaPlayer.timeControlStatus.Playing\n");
            break;
    }
#endif
    
    [self _postNotification:SJMediaPlayerTimeControlStatusDidChangeNotification];
}

- (void)setDuration:(NSTimeInterval)duration {
    _duration = duration;
    [self _postNotification:SJMediaPlayerDurationDidChangeNotification];
}

- (void)setPlayableDuration:(NSTimeInterval)playableDuration {
    _playableDuration = playableDuration;
    [self _postNotification:SJMediaPlayerPlayableDurationDidChangeNotification];
}

- (void)setIsPlaybackFinished:(BOOL)isPlaybackFinished {
    if ( isPlaybackFinished != _isPlaybackFinished ) {
        if ( !isPlaybackFinished ) _finishedReason = nil;
        _isPlaybackFinished = isPlaybackFinished;
        if ( isPlaybackFinished ) {
            [self _postNotification:SJMediaPlayerPlaybackDidFinishNotification];
        }
    }
}

- (void)setScalingMode:(CicadaScalingMode)scalingMode {
    _player.scalingMode = scalingMode;
}

- (CicadaScalingMode)scalingMode {
    return _player.scalingMode;
}

- (void)setPresentationSize:(CGSize)presentationSize {
    _presentationSize = presentationSize;
    [self _postNotification:SJMediaPlayerPresentationSizeDidChangeNotification];
}

- (void)setRate:(float)rate {
    _rate = rate;
    _player.rate = rate;
}

- (void)setVolume:(float)volume {
    _volume = volume;
    _player.volume = volume;
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    _player.muted = muted;
}

- (NSTimeInterval)playableDuration {
    if ( _trialEndPosition != 0 && _playableDuration >= _trialEndPosition ) {
        return _trialEndPosition;
    }
    return _playableDuration;
}

- (NSTimeInterval)currentTime {
    if ( _isPlaybackFinished ) {
        if ( _finishedReason == SJFinishedReasonToEndTimePosition )
            return _duration;
        else if ( _finishedReason == SJFinishedReasonToTrialEndPosition )
            return _trialEndPosition;
    }
    return _seekingInfo.isSeeking ? CMTimeGetSeconds(_seekingInfo.time) : _currentTime;
}

- (void)applicationDidEnterBackground {
    if ( self.pauseWhenAppDidEnterBackground ) [self pause];
}

- (BOOL)isPlayedToTrialEndPosition {
    return self.trialEndPosition != 0 && self.currentTime >= self.trialEndPosition;
}

- (void)_didPlayToTrialEndPosition {
    if ( self.finishedReason != SJFinishedReasonToTrialEndPosition ) {
        self.finishedReason = SJFinishedReasonToTrialEndPosition;
        self.isPlaybackFinished = YES;
        [self pause];
    }
}

- (void)_didPlayToEndPositoion {
    if ( self.finishedReason != SJFinishedReasonToEndTimePosition ) {
        self.finishedReason = SJFinishedReasonToEndTimePosition;
        self.isPlaybackFinished = YES;
        self.reasonForWaitingToPlay = nil;
        self.timeControlStatus = SJPlaybackTimeControlStatusPaused;
    }
}

- (CMTime)_adjustSeekTimeIfNeeded:(CMTime)time {
    if ( _trialEndPosition != 0 && CMTimeGetSeconds(time) >= _trialEndPosition ) {
        time = CMTimeMakeWithSeconds(_trialEndPosition * 0.98, NSEC_PER_SEC);
    }
    return time;
}
@end

NSNotificationName const SJCicadaMediaPlayerOnTrackReadyNotification = @"SJCicadaMediaPlayerOnTrackReadyNotification";
NS_ASSUME_NONNULL_END
