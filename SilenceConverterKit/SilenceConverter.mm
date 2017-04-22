//
//  SilenceConverter.mm
//
//  Created by pebble8888 on 2017/04/22.
//  Copyright © 2017年 pebble8888. All rights reserved.
//

#include "SilenceConverter.h"
#include <Foundation/Foundation.h>

// opaque
typedef struct SilenceConverter {
    AudioStreamBasicDescription src_asbd;
    AudioStreamBasicDescription dst_asbd;
    double src_advanced; // [sec]
    AudioBufferList* abl;
    void* src_data;
} SilenceConverter;

static uint32_t kMaxSrcCount = 4096;

OSStatus SilenceConverterNew(const AudioStreamBasicDescription * inSourceFormat,
                           const AudioStreamBasicDescription * inDestinationFormat,
                           AudioConverterRef __nullable * __nonnull outAudioConverter)
{
    SilenceConverter* sil = new SilenceConverter;
    sil->src_asbd = *inSourceFormat;
    sil->dst_asbd = *inDestinationFormat; 
    sil->src_advanced = 0.0;
    const uint32_t sz = sizeof(UInt32) + 1 * sizeof(AudioBuffer);
    sil->abl = (AudioBufferList *)malloc(sz);
    sil->src_data = malloc(kMaxSrcCount * sil->src_asbd.mBytesPerFrame);
    sil->abl->mNumberBuffers = 1;
    sil->abl->mBuffers[0].mNumberChannels = sil->src_asbd.mChannelsPerFrame;
    sil->abl->mBuffers[0].mDataByteSize = kMaxSrcCount * sil->src_asbd.mBytesPerFrame;
    sil->abl->mBuffers[0].mData = sil->src_data;
    
    AudioConverterRef audio_ref = reinterpret_cast<AudioConverterRef>(sil);
    *outAudioConverter = audio_ref;
    return noErr;
}

OSStatus AudioConverterDispose(AudioConverterRef inAudioConverter)
{
    SilenceConverter* sil = reinterpret_cast<SilenceConverter*>(inAudioConverter);
    free(sil->abl);
    free(sil->src_data);
    delete sil;
    return noErr;
}

OSStatus SilenceConverterFillComplexBuffer(AudioConverterRef inAudioConverter,
                                AudioConverterComplexInputDataProc inInputDataProc,
                                void * __nullable inInputDataProcUserData,
                                UInt32 * ioOutputDataPacketSize,
                                AudioBufferList * outOutputData,
                                AudioStreamPacketDescription * __nullable outPacketDescription)
{
    SilenceConverter* sil = reinterpret_cast<SilenceConverter*>(inAudioConverter);
    const uint32_t dst_count = *ioOutputDataPacketSize;
    const double dst_duration = dst_count / (sil->dst_asbd.mSampleRate); 
    const UInt32 src_count = (uint32_t)((dst_duration - sil->src_advanced) * sil->src_asbd.mSampleRate);
    sil->src_advanced = sil-> src_advanced + ((double)src_count / (double)sil->src_asbd.mSampleRate) - dst_duration; 
    
    UInt32 remain = src_count;
    while (remain > 0){
        UInt32 feed_count = MIN(remain, kMaxSrcCount);
        (*inInputDataProc)(inAudioConverter,
                           &feed_count,
                           sil->abl,
                           NULL,
                           inInputDataProcUserData);
        remain -= feed_count;
    }
    for (UInt32 bufidx = 0; bufidx < outOutputData->mNumberBuffers; ++bufidx){
        AudioBuffer* buf = &(outOutputData->mBuffers[bufidx]);
        // set bytes length
        assert(dst_count * sil->dst_asbd.mBytesPerPacket <= buf->mDataByteSize);
        buf->mDataByteSize = MIN(dst_count * sil->dst_asbd.mBytesPerPacket, buf->mDataByteSize);
        memset(buf->mData, 0, buf->mDataByteSize);
    }
    return noErr;
}
