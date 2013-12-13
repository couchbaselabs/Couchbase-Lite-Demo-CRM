//
//  ContactsByOpportunityViewController.m
//  CBLiteCRM
//
//  Created by Ruslan on 12/10/13.
//  Copyright (c) 2013 Danil. All rights reserved.
//

#import "ContactsByOpportunityViewController.h"

#import "DataStore.h"
#import "ContactOpportunityStore.h"
#import "ContactOpportunity.h"
#import "Contact.h"
#import "ContactCell.h"
#import "ContactDetailsViewController.h"

@interface ContactsByOpportunityViewController ()

@end

@implementation ContactsByOpportunityViewController

- (void)updateQuery
{
    self.store = [DataStore sharedInstance].contactOpportunityStore;
    CBLQuery *query = [(ContactOpportunityStore*)self.store queryContactsForOpportunity:self.filteredOpp];
    self.dataSource.query = [query asLiveQuery];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"presentContactSelectionForOpportunity"]) {
        ContactsViewController* vc = (ContactsViewController*)segue.destinationViewController;
        vc.chooser = YES;
        vc.filteringOpportunity = self.filteredOpp;
        [vc setOnSelectContact:^(Contact * ct) {
            ContactOpportunity *ctOpp = [[ContactOpportunity alloc] initInDatabase:[DataStore sharedInstance].database withContact:ct andOpportunity:self.filteredOpp];
            NSLog(@"ContactOpportunity created %@", ctOpp);
        }];
    } else if ([segue.destinationViewController isKindOfClass:[ContactDetailsViewController class]]) {
        ContactDetailsViewController* vc = (ContactDetailsViewController*)segue.destinationViewController;
        vc.currentContact = [[ContactOpportunity modelForDocument:[self.currentSource rowAtIndex:[self.currentSource.tableView indexPathForSelectedRow].row].document] contact];
    }

}

- (IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self performSegueWithIdentifier:@"presentContactDetails" sender:self];
}

- (UITableViewCell *)couchTableSource:(CBLUITableSource *)source cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactCell *cell = [[source tableView] dequeueReusableCellWithIdentifier:kContactCellIdentifier];
    CBLQueryRow *row = [self.currentSource rowAtIndex:indexPath.row];
    ContactOpportunity *ctOpp = [ContactOpportunity modelForDocument:row.document];
    cell.contact = ctOpp.contact;
    return cell;
}

-(void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope
{
    NSError *err;
    CBLQuery *query = [self.store filteredQuery];
    CBLQueryEnumerator *enumer = [self.dataSource.query rows:&err];

    NSMutableArray *matches = [NSMutableArray new];
    for (NSUInteger i = 0; i < enumer.count; i++) {
        CBLQueryRow *row = [self.dataSource rowAtIndex:i];
        ContactOpportunity *ctOpp = [ContactOpportunity modelForDocument:row.document];
        NSString* searchableString = ctOpp.contact.email;
        if ([searchableString rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound)
            [matches addObject:ctOpp.document.documentID];
    }
    query.keys = matches;
    self.filteredDataSource.query = [query asLiveQuery];
}

@end
