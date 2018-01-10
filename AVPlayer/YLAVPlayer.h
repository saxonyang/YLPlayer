//
//  YLAVPlayer.h
//  ihuacheng
//
//  Created by 意林 on 2017/6/28.
//  Copyright © 2017年 fairzy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@class YLAVPlayer;
@protocol YLAVPlayerDelegate <NSObject>
@optional
-(void)YLAVPlayerUpdateCurrentTimeValue:(YLAVPlayer *)myplayer;
-(void)YLAVPlayerPlayFinish:(YLAVPlayer *)myplayer;
-(void)YLAVPlayerPlayPause:(YLAVPlayer *)myplayer;
-(void)YLAVPlayerToPlay:(YLAVPlayer *)myplayer;
@end

@interface YLAVPlayer : NSObject {
    BOOL _isReleaseNotification;
}
@property (nonatomic ,readwrite) AVPlayerItem *item;
@property (nonatomic ,readwrite) AVPlayer *player;
@property (nonatomic ,strong)        id timeObser;
@property (nonatomic ,assign)        float videoLength;
@property (nonatomic ,assign)        float currentTimeValue;
@property (nonatomic ,weak)        id <YLAVPlayerDelegate> delegate;

+ (instancetype)share;
+ (void)pause;
+ (void)play;
+ (void)stop;
+ (YLAVPlayer *)playFromFile:(NSString *)fileUrl delegate:(id <YLAVPlayerDelegate>)delegate;//本地播放
+ (YLAVPlayer *)playFromHttp:(NSString *)httpUrl delegate:(id <YLAVPlayerDelegate>)delegate;//网络播放
 - (void)playFromUrl:(NSURL *)url;
@end

