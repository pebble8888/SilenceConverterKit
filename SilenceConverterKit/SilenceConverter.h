//
//  SilenceConverter.h
//
//  Created by pebble8888 on 2017/04/22.
//  Copyright © 2017年 pebble8888. All rights reserved.
//

#ifndef SilenceConverter_h
#define SilenceConverter_h

#import <AudioToolBox/AudioToolBox.h>

#ifdef __cplusplus
extern "C" {
#endif

OSStatus
SilenceConverterNew(const AudioStreamBasicDescription * __nonnull inSourceFormat,
                    const AudioStreamBasicDescription * __nonnull inDestinationFormat,
                    AudioConverterRef __nullable * __nonnull outAudioConverter);

OSStatus 
AudioConverterDispose(AudioConverterRef __nonnull inAudioConverter);
    
OSStatus 
SilenceConverterFillComplexBuffer(AudioConverterRef __nonnull inAudioConverter,
                                  AudioConverterComplexInputDataProc __nonnull inInputDataProc, 
                                  void * __nullable inInputDataProcUserData,
                                  UInt32 * __nonnull ioOutputDataPacketSize,
                                  AudioBufferList * __nonnull outOutputData,
                                  AudioStreamPacketDescription * __nullable outPacketDescription);
#ifdef __cplusplus
}
#endif

#endif /* SilenceConverter_hpp */
