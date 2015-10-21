//
//  VideoHelper.m
//  coreAnimationToVideo
//
//  Created by Lucas Serruya on 10/20/15.
//  Copyright © 2015 Lucas Serruya. All rights reserved.
//

#import "LDSVideoHelper.h"
#import <UIKit/UIKit.h>

@implementation LDSVideoHelper

//creamos un video en xPath con xDuracion (en decimos de segundo), el video por defecto tiene el tamaño de la pantalla, esto cambiarlo mas adelante segun especificaciones
+ (void)createVideoVoidToPath:(NSString*)path durationInSeconds:(int)duration size:(CGSize)videoSize withCompletion:(void (^)(void))callbackBlock
{
    duration = duration*20;//paso de los segundos que vienen a su equivalente en escala que es 20 frames por segundo
    int numberOfFrames = duration; //Cada frame ocupa un decimo de segundo (1/20)
    
    videoSize.height -= 21; //todo:remover esto cuando ya no use el screensize
    
    UIImage *backImage = [self createImageWithColor:[UIColor purpleColor] size:CGSizeMake(videoSize.width, videoSize.height)];
    NSError *error = nil;
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:videoSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:videoSize.height], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:videoSettings];
    
    //Al adaptador le cargo los frames
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                                                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    CVPixelBufferRef buffer = NULL;
    CVPixelBufferPoolCreatePixelBuffer (NULL, adaptor.pixelBufferPool, &buffer);
    buffer = [self pixelBufferFromCGImage:[backImage CGImage] size:CGSizeMake(videoSize.width, videoSize.height)];
    [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero]; //El primer frame de todo el video
    
    int frameCount = 0;
    while (videoWriter.status != AVAssetExportSessionStatusFailed)
    {
        if(writerInput.readyForMoreMediaData){
            
            CMTime frameTime = CMTimeMake(1, 20 );
            CMTime lastTime=CMTimeMake(frameCount, 20);
            CMTime presentTime= CMTimeAdd(lastTime, frameTime);
            
            if (frameCount >= numberOfFrames)
            {
                buffer = NULL;
            }
            else
            {
                buffer = [self pixelBufferFromCGImage:[backImage CGImage] size:CGSizeMake(videoSize.width, videoSize.height)];
            }
            
            
            if (buffer)
            {
                [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
                frameCount++;
            }
            else
            {
                //Finish the session:
                [writerInput markAsFinished];
                [videoWriter finishWritingWithCompletionHandler:^{
                    NSLog(@"GRABADOOO");
                    NSLog(@"%ld", (long)videoWriter.status);
                    callbackBlock();
                }];
                
                CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
                
                break;
            }
        }
    }
}

+ (UIImage *)createImageWithColor:(UIColor *)color size:(CGSize)size {
    CGContextRef context;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    context = UIGraphicsGetCurrentContext();
    
    CGContextClearRect(context, (CGRect){ {0,0}, size} );
    CGContextSetFillColorWithColor(context, [color CGColor]);
    //    CGContextSetAlpha(overlayContext, 1);
    CGContextFillRect(context, (CGRect){ {0,0}, size} );
    return UIGraphicsGetImageFromCurrentImageContext();
}

+ (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image  size:(CGSize)imageSize
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, imageSize.width,
                                          imageSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, imageSize.width,
                                                 imageSize.height, 8, 4*imageSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    //    CGContextConcatCTM(context, frameTransform);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}



@end
