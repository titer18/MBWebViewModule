#import "WEBPDemoDecoder.h"
#import <SDWebImage/UIImage+WebP.h>

@implementation WEBPDemoDecoder

- (UIImage *)decodeWebpData: (NSData *)data {
    return [UIImage sd_imageWithWebPData:data];
}

@end
