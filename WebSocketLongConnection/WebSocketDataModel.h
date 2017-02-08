//
//  WebSocketDataModel.h
//  WebSocketLongConnection
//
//  Created by ziv on 2016/12/16.
//  Copyright © 2016年 ziv. All rights reserved.
//

/*
 * 实现思路：
 * 通过调用SocketRocket实现SRWebSocketDelegate代理实现长连接。
 * 通过WebSocketConnectionDelegate代理把消息转发到实现代理的控制器中，从而得到数据。
 *
 */

#import <Foundation/Foundation.h>

#import "SocketRocket/SRWebSocket.h"

#define WEBSOCKET_CONNECTED      @"1"
#define WEBSOCKET_DISCONNECTED   @"2"
#define WEBSOCKET_SUBSCRIBE      @"3"
#define WEBSOCKET_NSStringEncoding NSUTF8StringEncoding


@class WebSocketDataModel;

@protocol WebSocketConnectionDelegate <NSObject>

//连接服务器成功
- (void)webSocketDidOpen:(WebSocketDataModel *)webSocket;

//连接失败
- (void)webSocket:(WebSocketDataModel *)webSocket didFailWithError:(NSError *)error;

//连接断开(被动断开)
- (void)webSocket:(WebSocketDataModel *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

//网络波动
- (void)webSocket:(WebSocketDataModel *)webSocket didReceivePong:(NSData *)pongPayload;

//接收到消息
- (void)webSocket:(WebSocketDataModel *)webSocket didReceiveMessage:(id)message;

@end


@interface WebSocketDataModel : NSObject <SRWebSocketDelegate>

@property (nonatomic, weak) id <WebSocketConnectionDelegate> delegate;

//单例
+ (WebSocketDataModel *) sharedWebSocketDataModel;

//建立长连接
- (void) connection:(NSString *)wssUrl;

//连接状态
- (int) connectionedState;

//断开长连接
- (void) disConnection;

//发送二进制数据
- (void) sendBinaryMessage:(NSData *)data;

//发送常规文本数据
- (void) sendTextMessage:(NSString *)message;


@end
