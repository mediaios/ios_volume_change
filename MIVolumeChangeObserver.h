//
//  MIVolumeChangeObserver.h
//  QiParchisDemo
//
//  Created by Qi on 2024/1/23.
//

#import <Foundation/Foundation.h>
#import <AVFAudio/AVFAudio.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface MIVolumeChangeObserver : NSObject

+ (instancetype)shareInstance;
- (void)observeVolumeOnBackgroundThread;

@end





NS_ASSUME_NONNULL_END
