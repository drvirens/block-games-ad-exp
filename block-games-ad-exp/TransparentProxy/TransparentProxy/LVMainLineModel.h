//
//  LVMainLineModel.h
//  TransparentProxy
//
//  Created by Virendra Shakya on 8/11/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVMainLineModel : NSObject

@property (nonatomic , strong) NSString *title;
@property (nonatomic , strong) NSString *detail;

@property (nonatomic , strong) NSString *ip;
@property (nonatomic , strong) NSNumber *port;
@property (nonatomic , strong) NSString *password;

@property (nonatomic , assign , getter=isSelected) BOOL selected;
@end

NS_ASSUME_NONNULL_END
