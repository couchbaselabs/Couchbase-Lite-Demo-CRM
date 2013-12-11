//
//  ContactsStore.m
//  CBLiteCRM
//
//  Created by Danil on 04/12/13.
//  Copyright (c) 2013 Danil. All rights reserved.
//

#import "ContactsStore.h"
#import "Contact.h"
#import "Opportunity.h"
#import "Customer.h"

#import "ContactOpportunityStore.h"
#import "ContactOpportunity.h"
#import "DataStore.h"

@interface ContactsStore()
{
    CBLView* _contactsView;
    CBLView* _filteredContactsView;
}
@end

@implementation ContactsStore

- (id) initWithDatabase: (CBLDatabase*)database {
    self = [super initWithDatabase:database];
    if (self) {
        [self.database.modelFactory registerClass: [Contact class] forDocumentType: kContactDocType];
        _contactsView = [self.database viewNamed: @"contactsByName"];
        [_contactsView setMapBlock: MAPBLOCK({
            if ([doc[@"type"] isEqualToString: kContactDocType]) {
                if (doc[@"email"])
                    emit(doc[@"email"], doc[@"email"]);
            }
        }) version: @"1"];
        
        _filteredContactsView = [self.database viewNamed: @"filteredContacts"];
        [_filteredContactsView setMapBlock: MAPBLOCK({
            if ([doc[@"type"] isEqualToString: kContactDocType]) {
                NSString* email = doc[@"email"];
                if (email)
                    emit(email, doc);
            }
        }) version: @"2"];

    }
    return self;
}


- (void) createFakeContacts {
    for (NSDictionary *dict in [self getFakeContactsDictionary]) {
        Contact* contact = [self contactWithMail: [dict objectForKey:kEmail]];
        if (!contact) {
            contact = [[Contact alloc] initInDatabase:self.database
                                            withEmail: [dict objectForKey:kEmail]];
            contact.phoneNumber = [dict objectForKey:kPhone];
            contact.name = [dict objectForKey:kName];
            contact.position = [dict objectForKey:kPosition];
            NSError *error;
            if (![contact save:&error])
                NSLog(@"%@", error);
        }
    }
}

- (NSArray*)getFakeContactsDictionary {
    return @[[NSDictionary dictionaryWithObjectsAndKeys:
              kExampleUserName, kEmail,
              @"+8 321 2490", kPhone,
              @"Archibald", kName,
              @"Sales consultant", kPosition,
              @"Thomson Reuters", kCompanyName, nil],
             [NSDictionary dictionaryWithObjectsAndKeys:
              @"Tovarish@mail.com", kEmail,
              @"+3 634 2983", kPhone,
              @"Dave", kName,
              @"Presales consultant", kPosition,
              @"Brittish Telecommunications", kCompanyName, nil],
             [NSDictionary dictionaryWithObjectsAndKeys:
              @"Sestra@mail.com", kEmail,
              @"+4 623 1234", kPhone,
              @"Michael", kName,
              @"SOA", kPosition,
              @"Monitise", kCompanyName, nil],
             [NSDictionary dictionaryWithObjectsAndKeys:
              @"Brat@mail.com", kEmail,
              @"+2 132 9162", kPhone,
              @"Eugene", kName,
              @"Lead developer", kPosition,
              @"Hewlett-Packard", kCompanyName, nil]];
}

- (Contact*) createContactWithMailOrReturnExist: (NSString*)mail{
    Contact* ct = [self contactWithMail:mail];
    if(!ct)
        ct = [[Contact alloc] initInDatabase:self.database withEmail:mail];
    return ct;
}

- (Contact*) contactWithMail: (NSString*)mail{
    CBLDocument* doc = [self.database createDocument];
    if (!doc.currentRevisionID)
        return nil;
    return [Contact modelForDocument: doc];
}

- (CBLQuery*) queryContacts {
    CBLQuery* query = [_contactsView createQuery];
    query.descending = YES;
    return query;
}

- (CBLQuery*) queryContactsForOpportunity:(Opportunity*)opp
{
    CBLQuery* query = [_contactsView createQuery];
    CBLQuery *addedContactsQuery = [[DataStore sharedInstance].contactOpportunityStore queryContactsForOpportunity:opp];
    NSError *err;
    NSMutableArray *keys;
    keys = [NSMutableArray new];
    for (CBLQueryRow *r in [query rows:&err]) {
        Contact *ct = [Contact modelForDocument:r.document];
        BOOL exist = NO;
        for (CBLQueryRow *row in [addedContactsQuery rows:&err]) {
            ContactOpportunity *ctOpp = [ContactOpportunity modelForDocument:row.document];
            if ([ct.email isEqualToString:ctOpp.contact.email])
                exist = YES;
        }
        if (!exist)
            [keys addObject:ct.email];
    }
    query.keys = keys;
    return query;
}

- (CBLQuery *)queryContactsByCustomer:(Customer *)cust
{
    CBLView* view = [self.database viewNamed: @"contactsForCustomer"];
    if (!view.mapBlock) {
        [view setMapBlock: MAPBLOCK({
            if ([doc[@"type"] isEqualToString: kContactDocType]) {
                NSString* customerId = doc[@"customer"];
                if (customerId) {
                    emit(customerId, doc);
                }
            }
        }) reduceBlock: nil version: @"4"]; // bump version any time you change the MAPBLOCK body!
    }
    CBLQuery* query = [view createQuery];
    NSString* myCustID = cust.document.documentID;
    query.keys = @[myCustID];
    return query;
}
- (CBLQuery *)filteredQuery
{
    return [_filteredContactsView createQuery];
}

@end