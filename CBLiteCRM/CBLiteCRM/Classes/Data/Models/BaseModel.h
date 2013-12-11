//
//  BaseModel.h
//  CBLiteCRM
//
//  Created by Danil on 29/11/13.
//  Copyright (c) 2013 Danil. All rights reserved.
//


@interface BaseModel : CBLModel
@property (strong) NSString* uniqueField;
@property (strong) NSString* docType;

- (instancetype) initInDatabase: (CBLDatabase*)database;
+ (NSString*) docType;
@end
