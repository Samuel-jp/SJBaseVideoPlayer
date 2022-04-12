//
//  SJVideoPlayerURLAsset+SJCicadaMediaPlaybackAdd.m
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJVideoPlayerURLAsset+SJCicadaMediaPlaybackAdd.h"
#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN
@implementation SJVideoPlayerURLAsset (SJCicadaMediaPlaybackAdd)
- (instancetype)initWithSource:(__kindof CicadaSource *)source {
    return [self initWithSource:source playModel:SJPlayModel.new];
}
- (instancetype)initWithSource:(__kindof CicadaSource *)source playModel:(__kindof SJPlayModel *)playModel {
    return [self initWithSource:source startPosition:0 playModel:playModel];
}
- (instancetype)initWithSource:(__kindof CicadaSource *)source startPosition:(NSTimeInterval)startPosition {
    return [self initWithSource:source startPosition:startPosition playModel:SJPlayModel.new];
}
- (instancetype)initWithSource:(__kindof CicadaSource *)source startPosition:(NSTimeInterval)startPosition playModel:(__kindof SJPlayModel *)playModel {
    self = [super init];
    if ( self ) {
        self.source = source;
        self.startPosition = startPosition;
        self.playModel = playModel;
    }
    return self;
}

- (void)setSource:(__kindof CicadaSource * _Nullable)source {
    objc_setAssociatedObject(self, @selector(source), source, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (nullable __kindof CicadaSource *)source {
    __kindof CicadaSource *source = objc_getAssociatedObject(self, _cmd);
    if ( source == nil ) {
        if ( self.mediaURL != nil ) {
            source = CicadaUrlSource.alloc.init;
            [(CicadaUrlSource *)source setPlayerUrl:self.mediaURL];
            [self setSource:source];
        }
    }
    return source;
}

- (void)setAvpConfig:(nullable CicadaConfig *)avpConfig {
    objc_setAssociatedObject(self, @selector(avpConfig), avpConfig, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (nullable CicadaConfig *)avpConfig {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setAvpCacheConfig:(nullable CicadaCacheConfig *)avpCacheConfig {
    objc_setAssociatedObject(self, @selector(avpCacheConfig), avpCacheConfig, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (nullable CicadaCacheConfig *)avpCacheConfig {
    return objc_getAssociatedObject(self, _cmd);
}
@end

/// 切换清晰度时使用
@implementation SJVideoPlayerURLAsset (SJCicadaMediaSelectTrack)
- (instancetype)initWithSource:(__kindof CicadaSource *)source subTrackInfo:(CicadaTrackInfo *)trackInfo {
    return [self initWithSource:source subTrackInfo:trackInfo playModel:SJPlayModel.new];
}
- (instancetype)initWithSource:(__kindof CicadaSource *)source subTrackInfo:(CicadaTrackInfo *)trackInfo playModel:(__kindof SJPlayModel *)playModel {
    self = [self initWithSource:source playModel:playModel];
    if ( self ) {
        objc_setAssociatedObject(self, @selector(avpTrackInfo), trackInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return self;
}

- (nullable CicadaTrackInfo *)avpTrackInfo {
    return objc_getAssociatedObject(self, _cmd);
}
@end

NS_ASSUME_NONNULL_END
