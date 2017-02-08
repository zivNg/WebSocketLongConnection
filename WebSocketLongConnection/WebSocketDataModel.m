//
//  WebSocketDataModel.m
//  WebSocketLongConnection
//
//  Created by ziv on 2016/12/16.
//  Copyright © 2016年 ziv. All rights reserved.
//

#import "WebSocketDataModel.h"

@interface WebSocketDataModel ()

@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, strong) NSString    *connectionState;
@property (nonatomic, strong) NSTimer     *heartTimer;

@end

@implementation WebSocketDataModel

+ (WebSocketDataModel *) sharedWebSocketDataModel
{
    static WebSocketDataModel *webSocketDataModel = nil;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        webSocketDataModel = [[self alloc] init];
        [webSocketDataModel initModel];
    });
    
    return webSocketDataModel;
}

- (void)initModel
{
    self.connectionState = WEBSOCKET_DISCONNECTED;
}

#pragma mark -
#pragma mark - ConnectionType
- (void) connection:(NSString *)wssUrl
{
    // disconnect current connection
    [self disConnection];
    
    //init wss
    NSURL *url = [NSURL URLWithString:wssUrl];
    self.webSocket = [[SRWebSocket alloc] initWithURL:url];
    self.webSocket.delegate = self;
    
    //检查端口和wss信息
    NSString *scheme = [url scheme];
    if ([[url port] intValue] == 9001)
    {
        if (![scheme isEqualToString:@"ws"])
        {
            NSLog(@"该链接为测试链接.. 请更换..");
            assert(0);
        }
    }
    
    //open
    [self.webSocket open];
    
}

- (int) connectionedState
{
    return [self.connectionState intValue];
}

- (void) disConnection
{
    if (self.webSocket != nil)
    {
        self.webSocket.delegate = nil;
        [self.webSocket close];
    }
    
    [self.heartTimer invalidate];
    self.heartTimer = nil;
}

- (void) sendBinaryMessage:(NSData *)data
{
    [self.webSocket send:data];
}

- (void) sendTextMessage:(NSString *)message
{
    [self.webSocket send:message];
}

- (void)dealloc
{
    [self disConnection];
}

#pragma mark - 
#pragma mark - SRWebSocketDelegate
- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    self.connectionState = WEBSOCKET_CONNECTED;
    if ([self.delegate respondsToSelector:@selector(webSocketDidOpen:)])
    {
        //NSLog(@"转发到实现代理的地方..");
        [self.delegate webSocketDidOpen:self];
    }
    
    //心跳
    [self heartConnection];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.heartTimer = [NSTimer scheduledTimerWithTimeInterval:180.f target:self selector:@selector(heartConnection) userInfo:nil repeats:true];
        [[NSRunLoop currentRunLoop] run];
        
    });
}

- (void)heartConnection
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"id":@"001",@"name":@"ziv",@"message":@"test"} options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [self sendTextMessage:jsonString];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    self.connectionState = WEBSOCKET_DISCONNECTED;
    if ([self.delegate respondsToSelector:@selector(webSocket:didFailWithError:)])
    {
        //NSLog(@"转发到实现代理的地方..");
        [self.delegate webSocket:self didFailWithError:error];
    }
    
    //重连
    
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    self.connectionState = WEBSOCKET_SUBSCRIBE;
    if ([self.delegate respondsToSelector:@selector(webSocket:didCloseWithCode:reason:wasClean:)])
    {
        //NSLog(@"转发到实现代理的地方..");
        [self.delegate webSocket:self didCloseWithCode:code reason:reason wasClean:wasClean];
    }
    
    //被动与服务器断开连接
    [self disConnection];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload
{
    NSLog(@"网络波动..");
    if ([self.delegate respondsToSelector:@selector(webSocket:didReceivePong:)]) {
        //NSLog(@"转发到实现代理的地方..");
        [self.delegate webSocket:self didReceivePong:pongPayload];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSLog(@"message==>%@", message);
    if ([self.delegate respondsToSelector:@selector(webSocket:didReceiveMessage:)])
    {
        //NSLog(@"转发到实现代理的地方..");
        [self.delegate webSocket:self didReceiveMessage:message];
    }
}


@end
