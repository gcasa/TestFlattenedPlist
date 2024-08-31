//
//  main.m
//  TestFlattenedPlist
//
//  Created by Gregory John Casamento on 8/31/24.
//

#import <Foundation/Foundation.h>

// Function to generate a 24-character GUID (uppercase, alphanumeric, no dashes)
NSString *generateGUID() {
    NSString *characters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *guid = [NSMutableString stringWithCapacity:24];
    
    for (int i = 0; i < 24; i++) {
        NSUInteger index = arc4random_uniform((uint32_t)[characters length]);
        unichar c = [characters characterAtIndex:index];
        [guid appendFormat:@"%C", c];
    }
    
    return guid;
}

// Recursive function to flatten the property list
id flattenPropertyList(id propertyList, NSMutableDictionary *objects, NSString **rootObjectGUID) {
    if ([propertyList isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)propertyList;

        // Check if the dictionary has an "isa" element
        if ([dict objectForKey:@"isa"]) {
            // Generate a GUID for this dictionary
            NSString *guid = generateGUID();
            
            // If the "isa" is "PBXProject", set the rootObjectGUID
            if ([[dict objectForKey:@"isa"] isEqualToString:@"PBXProject"]) {
                *rootObjectGUID = guid;
            }
            
            // Add the dictionary to the objects array with its GUID
            NSMutableDictionary *flattenedDict = [NSMutableDictionary dictionary];
            for (id key in dict) {
                flattenedDict[key] = flattenPropertyList([dict objectForKey:key], objects, rootObjectGUID);
            }
            [objects setObject:flattenedDict forKey:guid];
            
            // Return the GUID to replace the dictionary
            return guid;
        } else {
            // Recursively process each value in the dictionary
            NSMutableDictionary *processedDict = [NSMutableDictionary dictionary];
            for (id key in dict) {
                processedDict[key] = flattenPropertyList([dict objectForKey:key], objects, rootObjectGUID);
            }
            return processedDict;
        }
    } else if ([propertyList isKindOfClass:[NSArray class]]) {
        // Recursively process each item in the array
        NSMutableArray *processedArray = [NSMutableArray array];
        for (id item in propertyList) {
            [processedArray addObject:flattenPropertyList(item, objects, rootObjectGUID)];
        }
        return processedArray;
    } else {
        // For non-collection types, return the item as-is
        return propertyList;
    }
}

// Main function to initiate the flattening process
NSDictionary *flattenPlist(id propertyList) {
    NSMutableDictionary *objects = [NSMutableDictionary dictionary];
    NSString *rootObjectGUID = nil;
    
    // Flatten the property list and find the rootObjectGUID
    flattenPropertyList(propertyList, objects, &rootObjectGUID);
    
    // Return the final structure
    return @{@"rootObject": rootObjectGUID, @"objects": objects};
}

// Example usage
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Example property list
        NSDictionary *plist = @{
            @"name": @"Example Project",
            @"objects": @[
                @{
                    @"isa": @"PBXProject",
                    @"projectName": @"Example",
                    @"targets": @[
                        @{
                            @"isa": @"PBXNativeTarget",
                            @"name": @"App"
                        },
                        @{
                            @"isa": @"PBXNativeTarget",
                            @"name": @"Tests"
                        }
                    ]
                }
            ]
        };

        NSDictionary *flattenedPlist = flattenPlist(plist);
        NSLog(@"%@", flattenedPlist);
    }
    return 0;
}
