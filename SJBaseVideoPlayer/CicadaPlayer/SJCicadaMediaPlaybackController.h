//
//  SJCicadaMediaPlaybackController.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJMediaPlaybackController.h"
#import "SJVideoPlayerURLAsset+SJCicadaMediaPlaybackAdd.h"
#import "SJCicadaMediaPlayer.h"
#import <CicadaPlayerSDK/CicadaPlayerSDK.h>

NS_ASSUME_NONNULL_BEGIN
@interface SJCicadaMediaPlaybackController : SJMediaPlaybackController
@property (nonatomic) CicadaSeekMode seekMode;
@property (nonatomic, strong, readonly, nullable) SJCicadaMediaPlayer *currentPlayer;

@property (nonatomic, copy, nullable) void(^onTrackReadyExeBlock)(SJCicadaMediaPlaybackController *playbackController);
@end
NS_ASSUME_NONNULL_END
