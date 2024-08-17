//
//  PacketTunnelProvider.m
//  TheExtension
//
//  Created by Virendra Shakya on 8/11/24.
//

#import <os/log.h>
#import "PacketTunnelProvider.h"

@interface PacketTunnelProvider () <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *socket;

@end

@implementation PacketTunnelProvider


  // Define a custom log object for your subsystem and category
static os_log_t myLog;

+ (void)initialize {
  if (self == [PacketTunnelProvider self]) {
      // Create a log object with a specific subsystem and category
    myLog = os_log_create("ai.msg.nxt.TransparentProxy.TheExtension", "networking-extension");
  }
}
- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler {
  NSLog(@"VIREN: PacketTunnelProvider ::startTunnelWithOptions");
  os_log(myLog, "Starting tunnel with options...");
  
    // Set the tunnel's remote address to something meaningful for testing.
  NEPacketTunnelNetworkSettings *networkSettings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"8.8.8.8"];
  
    // Assign an IP address to the tunnel interface.
  networkSettings.IPv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[@"192.168.1.2"] subnetMasks:@[@"255.255.255.0"]];
  
    // Set up the route to direct all traffic through the tunnel (0.0.0.0/0).
  NEIPv4Route *defaultRoute = [NEIPv4Route defaultRoute];
  networkSettings.IPv4Settings.includedRoutes = @[defaultRoute];
  
    // Set up DNS to use Cloudflare's DNS server (8.8.8.8).
  networkSettings.DNSSettings = [[NEDNSSettings alloc] initWithServers:@[@"8.8.8.8"]];
  
    // Apply the network settings to the tunnel.
  [self setTunnelNetworkSettings:networkSettings completionHandler:^(NSError * _Nullable error) {
    if (error) {
      NSLog(@"VIREN PacketTunnelProvider Failed to set network settings: %@", error);
      os_log(myLog, "Set Tunnel Network settings failed with error: %{public}@", error);
      completionHandler(error);
      return;
    }
    
    os_log(myLog, "Set Tunnel Network settings succeeded with error: %{public}@", error);
    
      // Start reading and handling packets.
    [self startHandlingPackets];
    
    NSLog(@"VIREN PacketTunnelProvider Tunnel started successfully");
    completionHandler(nil);
  }];
  
  os_log(myLog, "last synchronous line of start tunnel fn");
}

- (void)startHandlingPackets {
  os_log(myLog, "Will start handling packets now....");
  
    // Establish the socket connection to the VPN server
  self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
  NSError *error = nil;
  if (![self.socket connectToHost:@"8.8.8.8" onPort:443 error:&error]) {
    os_log_error(myLog, "Error connecting to VPN server: %{public}@", error);
    return;
  }
  
  [self.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> *packets, NSArray<NSNumber *> *protocols) {
    for (NSData *packet in packets) {
      os_log(myLog, "OMG it works VIREN!!! processing packet ....%{public}@ ", packet);
      
        // Send the packet to the VPN server
      [self.socket writeData:packet withTimeout:-1 tag:0];
    }
    
      // Continue reading more packets.
    [self startHandlingPackets];
  }];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
  os_log(myLog, "Packet sent to VPN server successfully.");
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
  os_log_error(myLog, "Socket disconnected with error: %{public}@", err);
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
  NSLog(@"Stopping tunnel");
  
    // Clean up resources, close connections, etc.
  completionHandler();
}


@end
