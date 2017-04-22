//
//  NormalAudioConverterTests.mm
//
//  Created by pebble8888 on 2017/04/22.
//  Copyright © 2017年 pebble8888. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <assert.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolBox/AudioToolBox.h>

@interface NormalAudioConverterTests : XCTestCase
@end

@implementation NormalAudioConverterTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

static const int32_t kBufSize = 1024;
static float src_data[kBufSize];

static OSStatus encoderDataProc(AudioConverterRef inAudioConveter,
                                   UInt32* ioNumberDataPackets,
                                   AudioBufferList* ioData,
                                   AudioStreamPacketDescription **outDataPacketDescription,
                                   void* inUserData)
{
    static const float delta = 440 * 2 * M_PI / 44100;
    static int64_t x = 0;
    // It may feed less data for requested size.
    uint32_t count = MIN(*ioNumberDataPackets, kBufSize);
    //printf("count %d\n", count);
    
    float* p = src_data;
    for (int idx = 0; idx < count; ++idx) {
        *(p++) = sin((x+idx)*delta); 
    }
    x += count;
   
    ioData->mBuffers[0].mDataByteSize = sizeof(float) * count;
    ioData->mBuffers[0].mData = src_data;
    return noErr;
}

static void convert(void){
    const int32_t dst_sample_rate = 48000; 
    //const int32_t dst_sample_rate = 192000; 
    AVAudioFormat* srcfmt = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:1];
    AVAudioFormat* dstfmt = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:dst_sample_rate channels:1];
    AudioConverterRef ref;
    OSStatus status;
    status = AudioConverterNew(srcfmt.streamDescription, dstfmt.streamDescription, &ref);
    assert(status == noErr);
   
    UInt32 ioOutputDataPacketSize = kBufSize;
    float * dst_data = new float[kBufSize];
    const uint32_t sz = sizeof(UInt32) + 1 * sizeof(AudioBuffer);
    AudioBufferList* abl = (AudioBufferList *)malloc(sz);
    abl->mNumberBuffers = 1;
    abl->mBuffers[0].mNumberChannels = 1;
    abl->mBuffers[0].mDataByteSize = sizeof(float) * kBufSize;
    abl->mBuffers[0].mData = dst_data; 
    int64_t remain = 24 * 60 * 60 * (dst_sample_rate / kBufSize);
    while (remain > 0){
        status = AudioConverterFillComplexBuffer(ref, encoderDataProc, NULL, &ioOutputDataPacketSize, abl, NULL);
        assert(status == noErr);
        remain -= ioOutputDataPacketSize;
    }
    
    delete [] dst_data;
    free(abl);
}

- (void)testPerformance {
    [self measureBlock:^{
        convert();
    }];
}

@end
