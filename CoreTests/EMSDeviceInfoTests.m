//
//  Copyright (c) 2017 Emarsys. All rights reserved.
//

#import "Kiwi.h"
#import "EMSDeviceInfo.h"
#import <AdSupport/AdSupport.h>

SPEC_BEGIN(EMSDeviceInfoTests)

    context(@"Timezone", ^{
        __block NSTimeZone *cachedTimeZone;

        beforeAll(^{
            cachedTimeZone = [NSTimeZone defaultTimeZone];
            [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Budapest"]];
        });

        afterAll(^{
            [NSTimeZone setDefaultTimeZone:cachedTimeZone];
        });

        describe(@"timeZone", ^{

            it(@"should not return nil", ^{
               [[[EMSDeviceInfo timeZone] shouldNot] beNil];
            });

            it(@"should return with the current timeZone", ^{
                NSString *timeZone = [EMSDeviceInfo timeZone];
                [[timeZone should] equal:@"+0100"];
            });

        });

        describe(@"languageCode", ^{
            it(@"should not return nil", ^{
                [[[EMSDeviceInfo languageCode] shouldNot] beNil];
            });
        });

        describe(@"deviceModel", ^{
            it(@"should not return nil", ^{
                [[[EMSDeviceInfo deviceModel] shouldNot] beNil];
            });
        });

        describe(@"osVersion", ^{
            it(@"should not return nil", ^{
                [[[EMSDeviceInfo osVersion] shouldNot] beNil];
            });
        });
    });

    context(@"HWID", ^{

        id (^createIdentifierManagerMock)() = ^id() {
            id identifierMock = [ASIdentifierManager mock];

            [[ASIdentifierManager should] receive:@selector(sharedManager)
                                        andReturn:identifierMock
                                 withCountAtLeast:0];
            return identifierMock;
        };

        id (^createUserDefaultsMock)() = ^id() {
            id userDefaultsMock = [NSUserDefaults mock];

            [[userDefaultsMock should] receive:@selector(setObject:forKey:) withCountAtLeast:0];
            [[userDefaultsMock should] receive:@selector(synchronize) withCountAtLeast:0];

            [[NSUserDefaults should] receive:@selector(standardUserDefaults)
                                   andReturn:userDefaultsMock
                            withCountAtLeast:0];

            return userDefaultsMock;
        };

        describe(@"hardwareId", ^{

            it(@"should not return nil", ^{
                [[[EMSDeviceInfo hardwareId] shouldNot] beNil];
            });


            it(@"should return idfv if idfa is not available and there is no cached hardwareId", ^{
                [[createUserDefaultsMock() should] receive:@selector(objectForKey:)
                                                 andReturn:nil
                                          withCountAtLeast:0];

                id identifierManagerMock = createIdentifierManagerMock();
                [[identifierManagerMock should] receive:@selector(isAdvertisingTrackingEnabled)
                                              andReturn:theValue(NO)
                                       withCountAtLeast:1];

                NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
                [[[EMSDeviceInfo hardwareId] should] equal:idfv];
            });


            it(@"should return idfa if available and there is no cached hardwareId", ^{
                [[createUserDefaultsMock() should] receive:@selector(objectForKey:)
                                                 andReturn:nil
                                          withCountAtLeast:0];

                id identifierManagerMock = createIdentifierManagerMock();

                [[identifierManagerMock should] receive:@selector(isAdvertisingTrackingEnabled)
                                              andReturn:theValue(YES)
                                       withCountAtLeast:1];

                NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"E621E1F8-C36C-495A-93FC-0C247A3E6E5F"];
                [[identifierManagerMock should] receive:@selector(advertisingIdentifier)
                                              andReturn:uuid
                                       withCountAtLeast:0];

                [[[EMSDeviceInfo hardwareId] should] equal:[uuid UUIDString]];
            });


            it(@"should return the cached value if available", ^{
                [[createUserDefaultsMock() should] receive:@selector(objectForKey:)
                                                 andReturn:@"cached uuid"
                                          withCountAtLeast:0];
                id identifierManagerMock = createIdentifierManagerMock();

                __block int counter = 0;
                [identifierManagerMock stub:@selector(isAdvertisingTrackingEnabled) withBlock:^id(NSArray *params) {
                    return counter++ == 0 ? theValue(NO) : theValue(YES);
                }];

                NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"E621E1F8-C36C-495A-93FC-0C247A3E6E5F"];
                [[identifierManagerMock should] receive:@selector(advertisingIdentifier)
                                              andReturn:uuid
                                       withCountAtLeast:0];

                [[[EMSDeviceInfo hardwareId] should] equal:[EMSDeviceInfo hardwareId]];
            });
        });
    });

SPEC_END