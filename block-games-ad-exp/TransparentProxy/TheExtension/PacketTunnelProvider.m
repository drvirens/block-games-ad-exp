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
  os_log(myLog, "virenExtension: Starting tunnel with options...");
  
    // Cast the protocolConfiguration to NETunnelProviderProtocol to access providerConfiguration
  NETunnelProviderProtocol *protocol = (NETunnelProviderProtocol *)self.protocolConfiguration;
  
    // Extract the ovpnContents from the provider configuration
  NSString *ovpnContents = protocol.providerConfiguration[@"ovpnContents"];
  
    // Parse ovpnContents to extract the server address
  NSString *serverAddress;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"remote\\s+([\\d\\.]+)\\s+(\\d+)" options:0 error:nil];
  NSTextCheckingResult *match = [regex firstMatchInString:ovpnContents options:0 range:NSMakeRange(0, [ovpnContents length])];
  if (match) {
    serverAddress = [ovpnContents substringWithRange:[match rangeAtIndex:1]];
    os_log(myLog, "virenExtension: Extracted server address from ovpnContents: %{public}@", serverAddress);
  } else {
    os_log_error(myLog, "virenExtension: Could not find server address in ovpnContents.");
    NSError *error = [NSError errorWithDomain:@"PacketTunnelProviderErrorDomain"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Server address not found in ovpnContents."}];
    completionHandler(error);
    return;
  }
  
    // Configure the VPN tunnel using NEPacketTunnelNetworkSettings
  NEPacketTunnelNetworkSettings *settings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:serverAddress];
  
    // Configure IP settings
  NEIPv4Settings *ipv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[@"10.8.0.2"] subnetMasks:@[@"255.255.255.0"]];
  ipv4Settings.includedRoutes = @[[NEIPv4Route defaultRoute]];
  settings.IPv4Settings = ipv4Settings;
  
    // Set DNS servers (example using Google's public DNS)
  settings.DNSSettings = [[NEDNSSettings alloc] initWithServers:@[@"8.8.8.8", @"8.8.4.4"]];
  
    // Apply the settings
  [self setTunnelNetworkSettings:settings completionHandler:^(NSError * _Nullable error) {
    if (error) {
      os_log_error(myLog, "virenExtension: Failed to apply tunnel network settings: %{public}@", error.localizedDescription);
      completionHandler(error);
      return;
    }
    
      // Start handling packets once the tunnel is established
    [self startHandlingPackets];
    os_log(myLog, "virenExtension: Tunnel network settings applied successfully.");
    completionHandler(nil);
  }];
}

- (void)startHandlingPackets {
  os_log(myLog, "virenExtension: Will start handling packets now....");
  
  [self.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> *packets, NSArray<NSNumber *> *protocols) {
    NSMutableArray<NSData *> *processedPackets = [NSMutableArray array];
    NSMutableArray<NSNumber *> *processedProtocols = [NSMutableArray array];
    
    for (NSData *packet in packets) {
      os_log(myLog, "virenExtension: readPacketsWithCompletionHandler ....%{public}@ ", packet);
      
        // Process the packet as needed (e.g., modify, encrypt, forward, etc.)
        // For now, we'll just pass the packet through unmodified
      [processedPackets addObject:packet];
      [processedProtocols addObject:@([protocols indexOfObject:packet])];
    }
    
      // Write the processed packets back to the network
    [self.packetFlow writePackets:processedPackets withProtocols:processedProtocols];
    
    os_log(myLog, "virenExtension: writePackets processedPackets  withProtocols....%{public}@ ", processedProtocols);
    
      // Continue reading more packets.
    [self startHandlingPackets];
  }];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
  NSLog(@"Stopping tunnel");
  
    // Clean up resources, close connections, etc.
  completionHandler();
}

@end
