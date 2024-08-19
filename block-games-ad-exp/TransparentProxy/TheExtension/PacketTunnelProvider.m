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
  
    // Setup the VPN connection using the extracted server address and ovpnContents
  
    // Convert ovpnContents to NSData to pass to the OpenVPN library (assuming such a library is used)
  NSData *ovpnData = [ovpnContents dataUsingEncoding:NSUTF8StringEncoding];
  
    // Placeholder code for OpenVPN setup, replace with actual implementation
  NSError *vpnError;
  BOOL success = [self setupOpenVPNWithConfigData:ovpnData serverAddress:serverAddress error:&vpnError];
  
  if (success) {
    os_log(myLog, "virenExtension: VPN tunnel started successfully with server address: %{public}@", serverAddress);
    completionHandler(nil);
  } else {
    os_log_error(myLog, "virenExtension: Failed to start VPN tunnel with error: %{public}@", vpnError.localizedDescription);
    completionHandler(vpnError);
  }
}

- (BOOL)setupOpenVPNWithConfigData:(NSData *)configData serverAddress:(NSString *)serverAddress error:(NSError **)error {
    // This is a placeholder method for setting up the OpenVPN connection
    // Replace with the actual implementation using the OpenVPN library
  
    // Example of how it might be implemented (this is pseudocode)
  /*
   OpenVPNConfiguration *config = [[OpenVPNConfiguration alloc] initWithData:configData];
   config.serverAddress = serverAddress;
   OpenVPNManager *manager = [OpenVPNManager sharedManager];
   BOOL result = [manager startVPNWithConfiguration:config error:error];
   return result;
   */
  
    // Placeholder return value
  return YES; // Return YES if successful, NO if there was an error
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
