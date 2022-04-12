//
//  SJVideoPlayerURLAsset+SJCicadaMediaPlaybackAdd.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJVideoPlayerURLAsset.h"
#import <CicadaPlayerSDK/CicadaPlayerSDK.h>

NS_ASSUME_NONNULL_BEGIN
@interface SJVideoPlayerURLAsset (SJCicadaMediaPlaybackAdd)
- (instancetype)initWithSource:(__kindof CicadaSource *)source;
- (instancetype)initWithSource:(__kindof CicadaSource *)source playModel:(__kindof SJPlayModel *)playModel;
- (instancetype)initWithSource:(__kindof CicadaSource *)source startPosition:(NSTimeInterval)startPosition;
- (instancetype)initWithSource:(__kindof CicadaSource *)source startPosition:(NSTimeInterval)startPosition playModel:(__kindof SJPlayModel *)playModel;

@property (nonatomic, strong, readonly, nullable) __kindof CicadaSource *source;
@property (nonatomic, strong, nullable) CicadaConfig *avpConfig;
@property (nonatomic, strong, nullable) CicadaCacheConfig *avpCacheConfig;
@end

/// 切换清晰度时使用
@interface SJVideoPlayerURLAsset (SJCicadaMediaSelectTrack)
- (instancetype)initWithSource:(__kindof CicadaSource *)source subTrackInfo:(CicadaTrackInfo *)trackInfo;
- (instancetype)initWithSource:(__kindof CicadaSource *)source subTrackInfo:(CicadaTrackInfo *)trackInfo playModel:(__kindof SJPlayModel *)playModel;
@property (nonatomic, strong, readonly, nullable) CicadaTrackInfo *avpTrackInfo;
@end
NS_ASSUME_NONNULL_END
