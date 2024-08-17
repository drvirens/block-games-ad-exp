//
//  PacketTunnelProvider.m
//  TheExtension
//
//  Created by Virendra Shakya on 8/11/24.
//

#import <os/log.h>
#import "PacketTunnelProvider.h"


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
  
    // Cast the protocolConfiguration to NETunnelProviderProtocol to access providerConfiguration
  NETunnelProviderProtocol *protocol = (NETunnelProviderProtocol *)self.protocolConfiguration;
    // Retrieve the server address from the provider configuration
  NSString *serverAddress = protocol.providerConfiguration[@"serverAddress"];
  if (serverAddress) {
    os_log(myLog, "Retrieved server address: %{public}@", serverAddress);
  } else {
    os_log_error(myLog, "No server address found in provider configuration.");
    NSError *error = [NSError errorWithDomain:@"PacketTunnelProviderErrorDomain"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Server address is missing in provider configuration."}];
    completionHandler(error);
    return;
  }

    // Continue with setting up the tunnel using the server address
  NEPacketTunnelNetworkSettings *networkSettings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:serverAddress];
  
    // Assign an IP address to the tunnel interface.
  networkSettings.IPv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[@"192.168.1.2"] subnetMasks:@[@"255.255.255.0"]];
  
    // Set up the route to direct all traffic through the tunnel (0.0.0.0/0).
  NEIPv4Route *defaultRoute = [NEIPv4Route defaultRoute];
  networkSettings.IPv4Settings.includedRoutes = @[defaultRoute];
  
    // Set up DNS to use a specific DNS server
  networkSettings.DNSSettings = [[NEDNSSettings alloc] initWithServers:@[@"8.8.8.8"]];
  
    // Apply the network settings to the tunnel.
  [self setTunnelNetworkSettings:networkSettings completionHandler:^(NSError * _Nullable error) {
    if (error) {
      os_log_error(myLog, "Set Tunnel Network settings failed with error: %{public}@", error);
      completionHandler(error);
      return;
    }
    
    os_log(myLog, "Set Tunnel Network settings succeeded.");
    
      // Start reading and handling packets.
    [self startHandlingPackets];
    
    os_log(myLog, "PacketTunnelProvider Tunnel started successfully");
    completionHandler(nil);
  }];
  
  os_log(myLog, "Last synchronous line of startTunnelWithOptions.");
}

//
//- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler {
//  NSLog(@"VIREN: PacketTunnelProvider ::startTunnelWithOptions");
//  os_log(myLog, "Starting tunnel with options...");
//  
//    // Set the tunnel's remote address to something meaningful for testing.
//  NEPacketTunnelNetworkSettings *networkSettings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"8.8.8.8"];
//  
//    // Assign an IP address to the tunnel interface.
//  networkSettings.IPv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[@"192.168.1.2"] subnetMasks:@[@"255.255.255.0"]];
//  
//    // Set up the route to direct all traffic through the tunnel (0.0.0.0/0).
//  NEIPv4Route *defaultRoute = [NEIPv4Route defaultRoute];
//  networkSettings.IPv4Settings.includedRoutes = @[defaultRoute];
//  
//    // Set up DNS to use Cloudflare's DNS server (8.8.8.8).
//  networkSettings.DNSSettings = [[NEDNSSettings alloc] initWithServers:@[@"8.8.8.8"]];
//  
//    // Apply the network settings to the tunnel.
//  [self setTunnelNetworkSettings:networkSettings completionHandler:^(NSError * _Nullable error) {
//    if (error) {
//      NSLog(@"VIREN PacketTunnelProvider Failed to set network settings: %@", error);
//      os_log(myLog, "Set Tunnel Network settings failed with error: %{public}@", error);
//      completionHandler(error);
//      return;
//    }
//    
//    os_log(myLog, "Set Tunnel Network settings succeeded with error: %{public}@", error);
//    
//      // Start reading and handling packets.
//    [self startHandlingPackets];
//    
//    NSLog(@"VIREN PacketTunnelProvider Tunnel started successfully");
//    completionHandler(nil);
//  }];
//  
//  os_log(myLog, "last synchronous line of start tunnel fn");
//}

- (void)startHandlingPackets {
  os_log(myLog, "Will start handling packets now....");

  
  [self.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> *packets, NSArray<NSNumber *> *protocols) {
    for (NSData *packet in packets) {
      os_log(myLog, "readPacketsWithCompletionHandler ....%{public}@ ", packet);
    }
    
      // Continue reading more packets.
    [self startHandlingPackets];
  }];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
  NSLog(@"Stopping tunnel");
  
    // Clean up resources, close connections, etc.
  completionHandler();
}


@end
