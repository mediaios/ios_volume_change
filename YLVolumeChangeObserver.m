//
//  YLVolumeChangeObserver.m
//  QiParchisDemo
//
//  Created by Qi on 2024/1/23.
//

#import "YLVolumeChangeObserver.h"
#import <QuartzCore/QuartzCore.h>



@interface YLVolumeChangeObserver()

@property (nonatomic,assign) CGFloat repeatTimeInterval;
@property  (nonatomic,assign) BOOL isSystemMute;
@property (nonatomic,assign) BOOL isActive;
@property (nonatomic,assign) NSKeyValueOperator volumeObservation;
@property (nonatomic,assign) SystemSoundID soundFileID;
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,assign) BOOL isActiveOldValue;
@property (nonatomic,assign) NSInteger originBGMusicVolume;

@end

@implementation YLVolumeChangeObserver


static YLVolumeChangeObserver *yl_instance = NULL;

- (instancetype)init
{
    if(self = [super init]){
        _repeatTimeInterval = 0.6;
        _isSystemMute = NO;
        _isActive = NO;
        _soundFileID = 0;
    }
    return self;
}

+ (instancetype)shareInstance
{
    if(yl_instance == NULL){
        yl_instance = [[YLVolumeChangeObserver alloc] init];
    }
    return yl_instance;
}


- (void)observeVolumeOnBackgroundThread
{
    NSLog(@"[VolumeObserve]: 开启声音开关和按键的监听");
    // 添加音量变化通知
    [self setupVolumeObserver];
    
    NSURL *soundFileURL = [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"silence" ofType:@"mp3"]];
    OSStatus status = AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundFileURL, &_soundFileID);

    if (status != kAudioServicesNoError) {
        NSLog(@"Failed to create system sound with error: %d", (int)status);
    }
    dispatch_queue_t checkQueue = dispatch_queue_create("qi_check_queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(checkQueue, ^{
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        NSLog(@"[VolumeObserve]: scheduled timer with interval",self.repeatTimeInterval);
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
        
        [runLoop addTimer:_timer forMode:NSRunLoopCommonModes];
        [runLoop run];
    });
    
}

- (void)timerAction
{
    [self monitorMute];
}

- (void)removeVolumeObserver
{
    NSLog(@"Monitor Mute");
    AudioServicesDisposeSystemSoundID(self.soundFileID);
    if(_timer){
        [_timer invalidate];
        _timer = nil;
        _volumeObservation = nil;
    }
}

- (void)monitorMute
{
    if(_soundFileID == 0)
        return;
    CFTimeInterval startPlayTime = CACurrentMediaTime();
    
    AudioServicesPlaySystemSoundWithCompletion(self.soundFileID, ^{
        CFTimeInterval playDuring = CACurrentMediaTime() - startPlayTime;
        BOOL isMute = playDuring < 0.12;
        if(self.isSystemMute == isMute)
            return;
        self.isSystemMute = isMute;
        
        NSLog(@"QiDebug, isMute: %d",self.isSystemMute);
    });
}

- (void)setupVolumeObserver {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
   [audioSession addObserver:self forKeyPath:@"outputVolume" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"outputVolume"]) {
        float currentVolume = [[AVAudioSession sharedInstance] outputVolume];
        [self volumeChanged:currentVolume];
    }
}

- (void)volumeChanged:(float)volume {
   
    NSLog(@"QiDebug, volume: %f",volume);
}

@end
    
