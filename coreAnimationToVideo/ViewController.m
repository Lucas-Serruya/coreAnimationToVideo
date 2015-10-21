//
//  ViewController.m
//  AVTests
//
//  Created by Cristian Pena on 10/15/15.
//  Copyright © 2015 Cristian Pena. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "LDSVideoHelper.h"
@interface ViewController ()

@property (strong, nonatomic) AVMutableVideoComposition *videoComp;
@property (strong, nonatomic) NSString *myPathDocs;

@property (weak, nonatomic) IBOutlet UILabel *questionLabel;
@property (weak, nonatomic) IBOutlet UILabel *answer1Label;
@property (weak, nonatomic) IBOutlet UILabel *answer2Label;
@property (weak, nonatomic) IBOutlet UILabel *answer3Label;
@property (weak, nonatomic) IBOutlet UILabel *answer4Label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //    [self loadLocalAsset];
    //    [self loadRemoteAsset];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self saveMovieToLibrary];
}

- (void)prepareMovie {
    
    // create animations
    [self addAnimationToView:self.questionLabel fromPoint:CGPointMake(0, -250) withDuration:0.5 delay:0];
    [self addAnimationToView:self.answer1Label fromPoint:CGPointMake(self.view.bounds.size.width, 0) withDuration:0.5 delay:0.2];
    [self addAnimationToView:self.answer2Label fromPoint:CGPointMake(self.view.bounds.size.width, 0) withDuration:0.5 delay:0.4];
    [self addAnimationToView:self.answer3Label fromPoint:CGPointMake(self.view.bounds.size.width, 0) withDuration:0.5 delay:0.6];
    [self addAnimationToView:self.answer4Label fromPoint:CGPointMake(self.view.bounds.size.width, 0) withDuration:0.5 delay:0.8];
    
    // add animations to video Layer
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    videoLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:self.questionLabel.layer];
    [parentLayer addSublayer:self.answer1Label.layer];
    [parentLayer addSublayer:self.answer2Label.layer];
    [parentLayer addSublayer:self.answer3Label.layer];
    [parentLayer addSublayer:self.answer4Label.layer];
    
    self.videoComp = [AVMutableVideoComposition videoComposition];
    self.videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}

- (void)exportMovie {
    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *tempPath = [docPaths objectAtIndex:0];
    NSLog(@"Temp Path: %@",tempPath);
    
    NSString *fileName = [NSString stringWithFormat:@"%@/output-anot.MOV",tempPath];
    NSFileManager *fileManager = [NSFileManager defaultManager] ;
    if([fileManager fileExistsAtPath:fileName ]){
        //NSError *ferror = nil ;
        //BOOL success = [fileManager removeItemAtPath:fileName error:&ferror];
    }
    
    NSURL *exportURL = [NSURL fileURLWithPath:fileName];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:self.videoComp presetName:AVAssetExportPresetHighestQuality]  ;
    exporter.outputURL = exportURL;
    //    exporter.videoComposition = animComp;
    exporter.outputFileType= AVFileTypeQuickTimeMovie;
    [exporter exportAsynchronouslyWithCompletionHandler:^(void){
        switch (exporter.status) {
            case AVAssetExportSessionStatusFailed:{
                NSLog(@"Fail");
                break;
            }
            case AVAssetExportSessionStatusCompleted:{
                NSLog(@"Success");
                break;
            }
                
            default:
                break;
        }
    }];
}

- (void)addAnimationToView:(UIView *)view fromPoint:(CGPoint)point withDuration:(CFTimeInterval)duration delay:(CFTimeInterval)delay {
    CGPoint viewOrigin = CGPointMake(view.layer.position.x + point.x, view.layer.position.y + point.y);
    view.layer.position = viewOrigin;
    CGPoint viewEnd = CGPointMake(viewOrigin.x - point.x, viewOrigin.y - point.y);
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
    anim.fromValue  = [NSValue valueWithCGPoint:viewOrigin];
    anim.toValue    = [NSValue valueWithCGPoint:viewEnd];
    anim.duration   = duration;
    anim.beginTime  = CACurrentMediaTime() + delay;
    anim.removedOnCompletion = true;
    anim.repeatCount = 1;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [view.layer addAnimation:anim forKey:@"position"];
    view.layer.position = viewEnd;
}


- (CGRect)moveRect:(CGRect)rect position:(CGPoint)point {
    return CGRectMake(rect.origin.x + point.x, rect.origin.y + point.y, rect.size.width, rect.size.height);
}

- (void)videoOutputWorking
{
    // 1 - Early exit if there's no video file selected
    AVAsset *videoAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:self.myPathDocs]];
    
    
    // 2 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    // 3 - Video track
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                         atTime:kCMTimeZero error:nil];
    
    // 3.1 - Create AVMutableVideoCompositionInstruction
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    
    // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
    BOOL isVideoAssetPortrait_  = NO;
    //    filtro para poner el video en pantalla completa
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ = UIImageOrientationRight;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ =  UIImageOrientationLeft;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        videoAssetOrientation_ =  UIImageOrientationUp;
    }
    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        videoAssetOrientation_ = UIImageOrientationDown;
    }
    //filtro para poner el video en pantalla completa
    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [videolayerInstruction setOpacity:0.0 atTime:videoAsset.duration];
    
    // 3.3 - Add instructions
    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    CGSize naturalSize;
    if(isVideoAssetPortrait_){
        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    } else {
        naturalSize = videoAssetTrack.naturalSize;
    }
    
    float renderWidth, renderHeight;
    renderWidth = naturalSize.width;
    renderHeight = naturalSize.height;
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    
    [self applyVideoEffectsToComposition:mainCompositionInst size:naturalSize];
    
    //     4 - Get path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"FinalVideo-%d.mov",arc4random() % 1000]];
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    
    
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=url;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mainCompositionInst;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self exportDidFinish:exporter];
        });
    }];
    
    
}

- (void)exportDidFinish:(AVAssetExportSession*)session {
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
            [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                    } else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"
                                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                    }
                });
            }];
        }
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}



- (void)saveMovieToLibrary
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    self.myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                        [NSString stringWithFormat:@"FinalVideo-%d.mov",arc4random() % 1000]];
    
    NSLog(@"video saved in path: %@", self.myPathDocs);
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    [LDSVideoHelper createVideoVoidToPath:self.myPathDocs durationInSeconds:50 size:screenRect.size withCompletion:^() {
        [self videoOutputWorking];
    }];
}

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
{
    // create animations
    [self addAnimationToView:self.questionLabel fromPoint:CGPointMake(0, -250) withDuration:0.5 delay:0];
    [self addAnimationToView:self.answer1Label fromPoint:CGPointMake(self.view.bounds.size.width, 0) withDuration:10 delay:0.2];
    [self addAnimationToView:self.answer2Label fromPoint:CGPointMake(self.view.bounds.size.width, 0) withDuration:10 delay:0.4];
    [self addAnimationToView:self.answer3Label fromPoint:CGPointMake(self.view.bounds.size.width, 0) withDuration:10 delay:0.6];
    [self addAnimationToView:self.answer4Label fromPoint:CGPointMake(self.view.bounds.size.width, 0) withDuration:10 delay:0.8];
    
    // add animations to video Layer
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:[self.questionLabel layer]];
    [parentLayer addSublayer:[self.answer1Label layer]];
    [parentLayer addSublayer:[self.answer2Label layer]];
    [parentLayer addSublayer:[self.answer3Label layer]];
    [parentLayer addSublayer:[self.answer4Label layer]];
    
    composition = [AVMutableVideoComposition videoComposition];
    composition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}



@end
