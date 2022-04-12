//
//  SJCicadaMediaPlayerLayerView.h
//  Pods
//
//  Created by BlueDancer on 2020/2/19.
//

#import <UIKit/UIKit.h>
#import "SJCicadaMediaPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface SJCicadaMediaPlayerLayerView : UIView<SJMediaPlayerView>
- (instancetype)initWithPlayer:(SJCicadaMediaPlayer *)player;
@property (nonatomic, strong, readonly) SJCicadaMediaPlayer *player;
@property (nonatomic) SJVideoGravity videoGravity;
@property (nonatomic, readonly, getter=isReadyForDisplay) BOOL readyForDisplay;
@end

NS_ASSUME_NONNULL_END
