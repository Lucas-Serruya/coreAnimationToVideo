//
//  VideoHelper.h
//  coreAnimationToVideo
//
//  Created by Lucas Serruya on 10/20/15.
//  Copyright © 2015 Lucas Serruya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface LDSVideoHelper : NSObject

+ (void)createVideoVoidToPath:(NSString*)path durationInSeconds:(int)duration size:(CGSize)videoSize withCompletion:(void (^)(void))callbackBlock;

@end
