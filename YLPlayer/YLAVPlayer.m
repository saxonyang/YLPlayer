//
//  YLAVPlayer.m
//  ihuacheng
//
//  Created by 意林 on 2017/6/28.
//  Copyright © 2017年 fairzy. All rights reserved.
//

#import "YLAVPlayer.h"

@interface YLAVPlayer ()



@end

@implementation YLAVPlayer

- (instancetype)init {
    self = [super init];
    if (self) {
        _isReleaseNotification = YES;
    }
    return self;
}

+ (instancetype)share {
    static dispatch_once_t onceToken;
    static YLAVPlayer *audio = nil;
    dispatch_once(&onceToken, ^{
        audio = [[self alloc] init];
    });
    return audio;
}

#pragma make -- public
///本地播放
+ (YLAVPlayer *)playFromFile:(NSString *)fileUrl delegate:(id <YLAVPlayerDelegate>)delegate {
    NSURL *url = [NSURL fileURLWithPath:fileUrl];
    YLAVPlayer *play = [YLAVPlayer share];
    play.delegate = delegate;
    [play playFromUrl:url];
    return play;
}

///网络播放
+ (YLAVPlayer *)playFromHttp:(NSString *)httpUrl delegate:(id <YLAVPlayerDelegate>)delegate {
    NSURL *url = [NSURL URLWithString:httpUrl];
    YLAVPlayer *play = [YLAVPlayer share];
    play.delegate = delegate;
    [play playFromUrl:url];
    return play;
}

+ (void)play {
    YLAVPlayer *myplayer = [YLAVPlayer share];
    [myplayer.player play];
}

+ (void)pause {
    YLAVPlayer *myplayer = [YLAVPlayer share];
    [myplayer.player pause];
}

+ (void)stop {
    YLAVPlayer *myplayer = [YLAVPlayer share];
    [myplayer remove];
}

- (void)playFromUrl:(NSURL *)url {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"YLAVPlayer" object:_delegate];
    [self remove];
    NSLog(@"%@",url);
    _item = [[AVPlayerItem alloc] initWithURL:url];
    _player = [AVPlayer playerWithPlayerItem:_item];
    [self addVideoKVO];
    [self addVideoTimerObserver];
    [self addVideoNotic];
    _isReleaseNotification = NO;
    [_player play];
}
#pragma make -- private

- (void)remove {
    if (_player.rate == 1.0 || _player.rate == -1.0) [_player pause];
    if (!_isReleaseNotification) {
        [self removeVideoKVO];
        [self removeVideoNotic];
        [self removeVideoTimerObserver];
        _isReleaseNotification = YES;
        NSLog(@"%@",NSStringFromSelector(_cmd));
    }
}

- (void)dealloc {
    [self remove];
}
#pragma mark - KVO
- (void)addVideoKVO {
    //KVO
    [_item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [_item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [_item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeVideoKVO {
    [_item removeObserver:self forKeyPath:@"status"];
    [_item removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString*, id> *)change context:(nullable void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = _item.status;
        switch (status) {
            case AVPlayerItemStatusReadyToPlay: {
                NSLog(@"AVPlayerItemStatusReadyToPlay");
                _videoLength = floor(_item.asset.duration.value * 1.0/ _item.asset.duration.timescale);
                if (_delegate && [_delegate respondsToSelector:@selector(YLAVPlayerToPlay:)]) [_delegate YLAVPlayerToPlay:self];
            }
                break;
            case AVPlayerItemStatusUnknown: {
                NSLog(@"AVPlayerItemStatusUnknown");}
                break;
            case AVPlayerItemStatusFailed: {
                NSLog(@"AVPlayerItemStatusFailed");
                NSLog(@"%@",_item.error);
                [_player pause];
                if (_delegate && [_delegate respondsToSelector:@selector(YLAVPlayerPlayPause:)]) [_delegate YLAVPlayerPlayPause:self];
            }
                break;
            default:
                break;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
    }
}
#pragma mark - Notic
- (void)addVideoNotic {
    //Notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];// 添加视频播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieJumped:) name:AVPlayerItemTimeJumpedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieStalle:) name:AVPlayerItemPlaybackStalledNotification object:nil]; //添加视频异常中断通知
    if (@available(iOS 8.2, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBcakground:)  name:NSExtensionHostWillResignActiveNotification object:nil];
    } else {
        // Fallback on earlier versions
    } //进入后台
    if (@available(iOS 8.2, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterPlayGround:) name:NSExtensionHostDidBecomeActiveNotification object:nil];
    } else {
        // Fallback on earlier versions
    } // 返回前台
}

- (void)removeVideoNotic {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemTimeJumpedNotification object:nil];
    if (@available(iOS 8.2, *)) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSExtensionHostWillResignActiveNotification object:nil];
    } else {
        // Fallback on earlier versions
    }
    if (@available(iOS 8.2, *)) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSExtensionHostDidBecomeActiveNotification object:nil];
    } else {
        // Fallback on earlier versions
    }
}

- (void)movieToEnd:(NSNotification *)notic {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    if (_delegate && [_delegate respondsToSelector:@selector(YLAVPlayerPlayPause:)]) [_delegate YLAVPlayerPlayPause:self];
    if (_delegate && [_delegate respondsToSelector:@selector(YLAVPlayerPlayFinish:)]) [_delegate YLAVPlayerPlayFinish:self];
}

- (void)movieJumped:(NSNotification *)notic {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)movieStalle:(NSNotification *)notic {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    if (_delegate && [_delegate respondsToSelector:@selector(YLAVPlayerPlayPause:)]) [_delegate YLAVPlayerPlayPause:self];
}

- (void)enterBcakground:(NSNotification *)notic {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    [_player pause];
    if (_delegate && [_delegate respondsToSelector:@selector(YLAVPlayerPlayPause:)]) [_delegate YLAVPlayerPlayPause:self];
}

- (void)enterPlayGround:(NSNotification *)notic {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    [_player play];
}

#pragma mark - TimerObserver
- (void)addVideoTimerObserver {
    __weak typeof (self)self_ = self;
    _timeObser = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 2) queue:NULL usingBlock:^(CMTime time) {
        self_.currentTimeValue = time.value*1.0/time.timescale/self_.videoLength;
        if (self_.delegate && [self_.delegate respondsToSelector:@selector(YLAVPlayerUpdateCurrentTimeValue:)]) [self_.delegate YLAVPlayerUpdateCurrentTimeValue:self_];
    }];
}

- (void)removeVideoTimerObserver {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    [_player removeTimeObserver:_timeObser];
}


@end
