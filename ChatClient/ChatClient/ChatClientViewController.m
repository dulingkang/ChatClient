//
//  ChatClientViewController.m
//  ChatClient
//
//  Created by ShawnDu on 16/8/29.
//  Copyright © 2016年 ShawnDu. All rights reserved.
//

#import "ChatClientViewController.h"

@interface ChatClientViewController ()<NSStreamDelegate, UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UIView *joinView;
@property (weak, nonatomic) IBOutlet UIView *chatView;
@property (weak, nonatomic) IBOutlet UITableView *displayMessageTableView;
@property (weak, nonatomic) IBOutlet UITextField *inputNameField;
@property (weak, nonatomic) IBOutlet UITextField *inputMessageField;

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSMutableArray *messages;
@end

@implementation ChatClientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initNetworkCommunication];
    self.inputNameField.text = @"shawn";
    self.messages = [[NSMutableArray alloc] init];
    
    self.displayMessageTableView.delegate = self;
    self.displayMessageTableView.dataSource = self;
}

#pragma mark - delegate method
#pragma mark stream delegate
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    NSLog(@"stream event %lu", (unsigned long)streamEvent);
    
    switch (streamEvent) {
            
            case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            break;
            case NSStreamEventHasBytesAvailable:
            
            if (theStream == self.inputStream) {
                
                uint8_t buffer[1024];
                NSUInteger len;
                
                while ([self.inputStream hasBytesAvailable]) {
                    len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSUTF8StringEncoding];
                        
                        if (nil != output) {
                            
                            NSLog(@"server said: %@", output);
                            [self messageReceived:output];
                            
                        }
                    }
                }
            }
            break;
            
            
            case NSStreamEventErrorOccurred:
            
            NSLog(@"Can not connect to the host!");
            break;
            
            case NSStreamEventEndEncountered:
            
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            theStream = nil;
            
            break;
        default:
            NSLog(@"Unknown event");
    }
    
}

#pragma mark tableview delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *message = (NSString *) [self.messages objectAtIndex:indexPath.row];
    
    static NSString *CellIdentifier = @"ChatCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = message;
    
    return cell;
}

#pragma mark - event response
- (IBAction)sendMessage:(id)sender {
    NSString *response  = [NSString stringWithFormat:@"msg:%@", self.inputMessageField.text];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outputStream write:[data bytes] maxLength:[data length]];
    self.inputMessageField.text = @"";
}

- (IBAction)joinChat:(id)sender {
    [self.view bringSubviewToFront:self.chatView];
    NSString *response  = [NSString stringWithFormat:@"iam:%@", self.inputNameField.text];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outputStream write:[data bytes] maxLength:[data length]];
}

#pragma mark - private method
- (void)initNetworkCommunication {
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"115.28.228.41", 6222, &readStream, &writeStream);
    
    self.inputStream = (__bridge NSInputStream *)readStream;
    self.outputStream = (__bridge NSOutputStream *)writeStream;
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    [self.outputStream open];
}

- (void)messageReceived:(NSString *)message {
    
    [self.messages addObject:message];
    [self.displayMessageTableView reloadData];
    NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:self.messages.count-1
                                                   inSection:0];
    [self.displayMessageTableView scrollToRowAtIndexPath:topIndexPath
                      atScrollPosition:UITableViewScrollPositionMiddle
                              animated:YES];
}

@end
