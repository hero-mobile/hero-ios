//
//  HeroSimpleStorage
//  hero-ios
//
//  Created by Liu Guoping on 2018/10/26.
//

#import <JavaScriptCore/JavaScriptCore.h>
#import <Objective_LevelDB/LevelDB.h>
#import "HeroDB.h"


@interface HeroDB ()


@end

static LevelDB *ldb;

@implementation HeroDB {
}

-(instancetype)init{
    if (!ldb) {
        ldb = [LevelDB databaseInLibraryWithName:@"hero.ldb"];
    }
    return [super init];
}

-(void)on:(NSDictionary *)json{
    [super on:json];
    NSString *key = json[@"key"];
    NSString *arrayKey = json[@"arrayKey"];
    NSString *start = json[@"start"];
    NSString *count = json[@"count"];
    id value = json[@"value"];
    
    if (key) {
        if (value) {
            [self setValue:value forKey:key];
        } else{
            id value = [self valueForKey:key];
            if (json[@"isNpc"]) {
                NSString *js = [NSString stringWithFormat:@"window['%@callback'](%@)",[self class], value];
                [self.controller.webview stringByEvaluatingJavaScriptFromString:js];
            } else {
                [self.controller on:@{@"result": value, @"key": key}];
            }
        }
    }
    
    if (arrayKey) {
        if (value) {
            [self addValue:value forArrayKey:arrayKey];
        } else if (start && count) {
            NSArray *value = [self valueForArrayKey:arrayKey start:[start integerValue] count:[count integerValue]];
            
            if (json[@"isNpc"]) {
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:nil];
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                NSString *js = [NSString stringWithFormat:@"window['%@callback'](%@)",[self class], jsonString];
                [self.controller.webview stringByEvaluatingJavaScriptFromString:js];
            } else {
                [self.controller on:@{@"result": value, @"arrayKey": arrayKey}];
            }
        
        }
    }
}

- (void)setValue:(id)value forKey:(NSString *)key {
    ldb.safe = YES;
    ldb[key] = value;
    ldb.safe = NO;
}

- (id)valueForKey:(NSString *)key {
    return ldb[key];
}

- (void)addValue:(id)value forArrayKey:(NSString *)arrayKey {
    NSMutableArray *array = [ldb[arrayKey] mutableCopy];
    ldb.safe = YES;
    if (array) {
        if ([value isKindOfClass:[NSArray class]]) {
            [array addObjectsFromArray:value];
        } else {
            [array addObject:value];
        }
    } else {
        array = [@[value] mutableCopy];
    }
    ldb[arrayKey] = array;
    ldb.safe = NO;
}

- (NSArray *)valueForArrayKey:(NSString *)arrayKey start:(NSUInteger)start count:(NSUInteger)count {
    NSArray *array = ldb[arrayKey];
    if (!array) {
        return @[];
    }
    NSInteger c = count;
    if (start + count > array.count) {
        c = array.count - start;
    }
    
    NSRange range = NSMakeRange(array.count - start - c, c);
    NSArray *value = [array subarrayWithRange:range];
    return value;
}

@end

