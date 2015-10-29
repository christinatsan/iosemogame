//
//  ViewController.m
//  test2
//
//  Created by Christina Tsangouri on 9/9/15.
//  Copyright (c) 2015 Christina Tsangouri. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/objdetect/objdetect.hpp>
#import <dispatch/dispatch.h>
#import "jsonnull.h"


@interface ViewController ()

-(cv::CascadeClassifier*)loadClassifier;


@end

@implementation ViewController

cv::Mat faceMat;
cv::Mat originalMat;
UIImage *image;
UIImage *faceicon;
UIImage *backgr;
cv::Mat grayMat;
cv::Mat tempMat;
UIImage *newImage;
cv::CascadeClassifier *faceCascade;
UIImage *faceImage;
UIImage *newim;
UIImage * explode;
static int currentfaceid=3;
static int pos=0;
bool faceDetected = false;
cv::Rect roi;
static int explodelast=0;
static int gamelife=4;
static int totalscore=0;
static int dropposx=100;
static int dropposy=0;
static int tempexpl=0;

NSString *happy;
NSString *sad;
NSString *fear;
NSString *neutral;
NSString *surprise;
NSString *angry;
NSString *disgust;
NSDictionary *emotions;
NSString *mainEmotion;
NSArray *emoString = [NSArray arrayWithObjects:@"happy",@"surprise",@"sad",@"fear",@"neutral",@"disgust",@"angry",nil];
//static int newstartx=0;
-(BOOL)prefersStatusBarHidden{
    return YES;
}
-(cv::CascadeClassifier*)loadClassifier
{
    NSString* haar = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"];
    cv::CascadeClassifier* cascade = new cv::CascadeClassifier();
    cascade->load([haar UTF8String]);
    return cascade;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
   
    //[self.startCamera setTitle:@"Start Camera" forState:UIControlStateNormal];
    //[self.resultButton setTitle:@"Show Result" forState:UIControlStateNormal];
    
    
    

    //[[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.highEmotion = @"happy";
    
    self.camera = [[CvVideoCamera alloc] initWithParentView:_faceView];
    self.camera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    //self.camera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.camera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.camera.defaultFPS = 15;
    self.camera.grayscaleMode = NO;
    self.camera.delegate = self;
    
    faceCascade = [self loadClassifier];
    [self.camera start];
    backgr=[UIImage imageNamed:@"backgr.png"];
    UIImage *facedemo;
    facedemo=[UIImage imageNamed:@"face.png"];
    [self createTimer];
    [self createTimer2];
    [self.baseimage setImage:backgr];
    [self.explodeeffect setImage:Nil];
    [self fillobj];
    explode=[UIImage imageNamed:@"touchgr"];
    [self.explodeeffect setImage:explode];
    self.explodeeffect.frame = CGRectMake(dropposx-35, 1000, 100, 100);
    //[self.imageView setImage:Nil];
    //[self.imageView setBounds:CGRectMake(10, 10, 20, 20)];
    
    //[self.imageView setImage:facedemo];
   // [self showResult];
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*- (void)viewDidAppear:(BOOL)animated {
    [self.imageView setImage:[UIImage imageNamed:@"coffeebeans.png"]];
}*/



- (void)showResult {
    if([self.highEmotion isEqualToString:@"happy"])
        [self.imageView setImage:[UIImage imageNamed:@"happy.jpeg"]];
    if([self.highEmotion isEqualToString:@"angry"])
        [self.imageView setImage:[UIImage imageNamed:@"angry.jpeg"]];
    if([self.highEmotion isEqualToString:@"disgust"])
        [self.imageView setImage:[UIImage imageNamed:@"disgust.jpeg"]];
    if([self.highEmotion isEqualToString:@"laughing"])
        [self.imageView setImage:[UIImage imageNamed:@"laughing.jpeg"]];
    if([self.highEmotion isEqualToString:@"neutral"])
        [self.imageView setImage:[UIImage imageNamed:@"neutral.jpeg"]];
    if([self.highEmotion isEqualToString:@"sad"])
        [self.imageView setImage:[UIImage imageNamed:@"sad.jpeg"]];
    if([self.highEmotion isEqualToString:@"fear"])
        [self.imageView setImage:[UIImage imageNamed:@"scared.jpeg"]];
    if([self.highEmotion isEqualToString:@"surprise"])
        [self.imageView setImage:[UIImage imageNamed:@"surprised.jpeg"]];
    
        
}

-(void) postImage {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW,0),^{
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        // NSDictionary *parameters = @{@"bookmark[title]" : @"photo.jpg"};
        if (faceImage!=Nil){
            NSData *imageData = UIImageJPEGRepresentation(faceImage, 0.5);
            //NSData *imageData = UIImageJPEGRepresentation(self.faceView.image,0.5);
            [manager POST:@"http://emo.vistawearables.com/bookmarks" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                [formData appendPartWithFileData:imageData name:@"bookmark[photo]" fileName:@"photo.jpg" mimeType:@"image/jpeg"];
            } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Success: %@", responseObject);
                // [self getResponse];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                
                [self getResponse];
                NSLog(@"Error: %@", error);
                
            }];
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSLog(@"get here");
            
        });
        
        
        
    });

}

- (void) findHighest {
    
    
    
    
    float happyInt = [happy floatValue];
    float surpriseInt = [surprise floatValue];
    float sadInt = [sad floatValue];
    float fearInt = [fear floatValue];
    float neutralInt = [neutral floatValue];
    float disgustInt = [disgust floatValue];
    float angryInt = [angry floatValue];
    
    float emo[7] = {happyInt,surpriseInt,sadInt,fearInt,neutralInt,disgustInt,angryInt};
    
    double largest = 0;
    
    for(int i=0;i<=6;i++){
        if(emo[i]>largest)
            largest = emo[i];
        
    }
    
    for(int i=0;i<=6;i++){
        if(emo[i] == largest)
            mainEmotion = emoString[i];
    }
    
    
}

-(void) getResponse {
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW,0),^{
        
        /* NSURL *url = [NSURL URLWithString:@"http://emo.vistawearables.com/bookmarks.json"];
         NSURLRequest *request = [NSURLRequest requestWithURL:url];
         
         // 2
         AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
         operation.responseSerializer = [AFJSONResponseSerializer serializer];
         
         [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
         
         NSLog(@"json: %@", responseObject);
         
         // 3
         emotions = (NSDictionary *)responseObject;
         //self.title = @"JSON Retrieved";
         happy = emotions[@"happy"];
         NSLog(@"HAPPY: %@",happy);
         
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         
         // 4
         NSLog(@"json error");
         }];
         
         // 5
         [operation start];*/
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        [manager GET:@"http://emo.vistawearables.com/bookmarks.json" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
            
            emotions = (NSDictionary *)responseObject;
            happy = emotions[@"happy"];
            surprise = emotions[@"surprise"];
            sad = emotions[@"sad"];
            fear = emotions[@"fear"];
            neutral = emotions[@"neutral"];
            disgust = emotions[@"disgust"];
            angry = emotions[@"angry"];
            
            NSLog(@"HAPPY: %@",happy);
            
            // [self findHighest];
            
            
            
            //            happy = json[@"happy"];
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"work here");
//            NSLog(@"after get main %@",happy);
//            [self findHighest];
//            self.resultText.text = mainEmotion;
        });
        
        
        
    });
    
}

- (IBAction)handleResultClick:(id)sender {
    [self showFace];
    
    //[self showResult];
}

/*- (IBAction)handleButtonClick:(id)sender {
    
    [self getMat];
    
    
    
    //self.textLabel.text = @"button pressed";
}*/

- (IBAction)handleStartCamera:(id)sender {
    [self.camera start];
    
}
- (IBAction)handlemvim:(id)sender {
    
    //NSString *string = [NSString stringWithFormat:@"www.baidu.com"];
    //NSURL *url = [NSURL URLWithString:string];
    //NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // 2
    //AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    //self.imageView.frame=CGRectMake(0,0,100,100);
//    CGRect oldFrame = self.faceView.frame;
//    CGRect newFrame = CGRectMake(oldFrame.origin.x, oldFrame.origin.y+50, oldFrame.size.width, oldFrame.size.height);
//    self.imageView.frame = newFrame;
    //self.faceView.transform = CGAffineTransformMakeRotation(M_PI_2);
}

#pragma mark - Protocol CvVideoCameraDelegate

- (void)processImage:(cv::Mat&)image
{
    // Do some OpenCV stuff with the image
    cv::Mat grayMat;
    cv::Mat face;
    cv::Mat imt;
    cv::Mat rgbMat;
    grayMat = cv::Mat(image.rows, image.cols, CV_8UC3);
    cvtColor(image, grayMat, CV_BGRA2GRAY);
    rgbMat = cv::Mat(image.rows, image.cols, CV_8UC3);
    cvtColor(image, rgbMat, CV_BGRA2RGB);
    
    int height = grayMat.rows;
    double faceSize = (double) height * 0.25;
    cv::Size sSize;
    sSize.height = faceSize;
    sSize.width = faceSize;
    std::vector<cv::Rect> faces;
    //cv::transpose(grayMat, grayMat);
    faceCascade->detectMultiScale(grayMat,faces,1.1,4,2, sSize);
    if(faces.size() > 0)
    {
        //NSLog(@"face detected here!");
        cv::rectangle(image, faces[0].tl(), faces[0].br(),cv::Scalar(84.36,170,0), 2, CV_AA);
        
        cv::Mat(rgbMat, faces[0]).copyTo(face);
        
        faceImage = [self UIImageFromCVMat:face];
        
        
    }
    //cv::transpose(image, image);
    cvtColor(image, image, CV_BGRA2RGB);
    //image=imt;
    if(faces.size() == 0)
        faceDetected = false;
    
    
    grayMat.release();
    //originalMat.release();
    rgbMat.release();
    
    
}
- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
- (IBAction)missilescore:(id)sender {
    totalscore+=1;
    NSString *strscr=[NSString stringWithFormat:@"Score: %d",totalscore];
    [self.scoretext setText:strscr];
    
}
- (void)showFace {
    faceImage=[UIImage imageNamed:@"face.png"];
    newim=[self imageWithImage:faceImage scaledToSize:CGSizeMake(75, 100)];
    
    //newim=[self imageWithImage:faceImage scaledToSize:CGSizeMake(50, 100)];
    [self.faceView setImage:newim];
    //self.faceView.frame=CGRectMake(0,0,100,100);
    // Save Face Image to Doc Directory
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *docs = [paths objectAtIndex:0];
    NSString* path =  [docs stringByAppendingFormat:@"/image1.jpg"];
    
    //filename = imageData
    NSData* imageData = [NSData dataWithData:UIImageJPEGRepresentation(faceImage, 80)];
    NSError *writeError = nil;
   [imageData writeToFile:path options:NSDataWritingAtomic error:&writeError];
    
    
    // Send to server
    
   // [self postImage];
    
}

/*- (void)postImage {
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:@"http:example.com/upload" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:@"file:path/to/image.jpg"] name:@"file" fileName:@"filename.jpg" mimeType:@"image/jpeg" error:nil];
    } error:nil];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSProgress *progress = nil;
    
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"%@ %@", response, responseObject);
        }
    }];

}*/

- (void)getMat {
    
    image = [UIImage imageNamed:@"happy.jpeg"];
    faceMat = [self cvMatFromUIImage:image];
    cvtColor(faceMat, grayMat, CV_BGRA2GRAY);
    newImage = [self UIImageFromCVMat:grayMat];
    [self.imageView setImage:newImage];
    
    
       // NSLog(@"things worked");
    
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}
- (IBAction)CamModeChg:(id)sender {
    
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

- (NSTimer*)createTimer {
    
    // create timer on run loop
    return [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(timerTicked:) userInfo:nil repeats:YES];
}

- (void)timerTicked:(NSTimer*)timer {
    
    [self showobj];

}

- (NSTimer*)createTimer2 {
    
    // create timer on run loop
    return [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerHit:) userInfo:nil repeats:YES];
}

- (void)timerHit:(NSTimer*)timer {
    
    [self postImage];
   // [self getResponse]; //(christina - im calling it when postImage finishes, check up)
    [self findHighest];
    [self.emostring setText:mainEmotion];
    //[self.emostring setText:(NSString * _Nullable)]
    
    
}
-(void)showlifeicon{
    if (gamelife<0)gamelife=0;
    if(gamelife==3){
//        CGRect newFrame = CGRectMake(300, 55, 22,22);
//        self.bld4.frame=newFrame;
        [self.bld4 setImage:Nil];
    }
    if(gamelife==2){
//        CGRect newFrame = CGRectMake(300, 55, 22,22);
//        self.bld3.frame=newFrame;
        [self.bld3 setImage:Nil];
    }
    if(gamelife==1){
//        CGRect newFrame = CGRectMake(300, 55, 22,22);
//        self.bld2.frame=newFrame;
        [self.bld2 setImage:Nil];
    }
    if(gamelife==0){
//        CGRect newFrame = CGRectMake(300, 55, 22,22);
//        self.bld1.frame=newFrame;
        [self.bld1 setImage:Nil];
    }
    if(gamelife==4){
//        CGRect newFrame = CGRectMake(7, 55, 22,22);
//        self.bld1.frame=newFrame;
//        newFrame = CGRectMake(32, 55, 22,22);
//        self.bld2.frame=newFrame;
//        newFrame = CGRectMake(57, 55, 22,22);
//        self.bld3.frame=newFrame;
//        newFrame = CGRectMake(82, 55, 22,22);
//        self.bld4.frame=newFrame;
    }
}
-(void)showobj{
    dropposy+=2;
    int temppos=dropposx;
    
    if(dropposy>500){
        //life update and redraw
        gamelife-=1;
        [self showlifeicon];
        //new face icon
        [self fillobj];
        explodelast=60;
        //self.explodeeffect.frame = CGRectMake(temppos-35, 430, 100, 100);
        dropposx= arc4random()%270;
        dropposy=0;
    }
    if (explodelast>0)explodelast-=1;
    if (explodelast==0)
    {
        self.explodeeffect.frame = CGRectMake(dropposx-35, 1000, 100, 100);
    }
    else{
        self.explodeeffect.frame = CGRectMake(temppos-35, 410, 100, 100);
    }
    self.imageView.frame = CGRectMake(dropposx,  dropposy, 48,47);
    //NSLog(@"%d %d",newstartx,t);

}
-(void)fillobj{
    currentfaceid=arc4random_uniform(7);
    int faceid=currentfaceid;
//    pos=arc4random()%270;
//    CGRect neoframe=CGRectMake(pos,0 ,48, 47);
//    [self.imageView setFrame:neoframe];
    //NSLog(@"%d ",pos);
    if (faceid==0){
        faceicon=[UIImage imageNamed:@"angry"];
        
        [self.imageView setImage:faceicon];
        
    }
    if (faceid==1){
        faceicon=[UIImage imageNamed:@"disgust"];
        [self.imageView setImage:faceicon];
    }
    if (faceid==2){
        faceicon=[UIImage imageNamed:@"fear"];
        [self.imageView setImage:faceicon];
    }
    if (faceid==3){
        faceicon=[UIImage imageNamed:@"happy"];
        [self.imageView setImage:faceicon];
    }
    if (faceid==4){
        faceicon=[UIImage imageNamed:@"neutral"];
        [self.imageView setImage:faceicon];
    }
    if (faceid==5){
        faceicon=[UIImage imageNamed:@"sad"];
        [self.imageView setImage:faceicon];
    }
    if (faceid==6){
        faceicon=[UIImage imageNamed:@"surprise"];
        [self.imageView setImage:faceicon];
    }

    
}

-(void)score{
    int s=10;
}

@end
