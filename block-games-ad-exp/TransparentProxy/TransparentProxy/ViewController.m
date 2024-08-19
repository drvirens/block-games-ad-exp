//
//  ViewController.m
//  TransparentProxy
//
//  Created by Virendra Shakya on 8/11/24.
//

#import <NetworkExtension/NetworkExtension.h>
#import <os/log.h>
#import "ViewController.h"
#import "LVMainLineModel.h"
#import "LVVPNManager.h"
#import "VPNCOnfiguration.h"

@interface ViewController ()

@property (nonatomic , strong) NSArray <NSArray <LVMainLineModel *> *> *modelArr;
@end

@implementation ViewController {
  
}


  // Define a custom log object for your subsystem and category
static os_log_t myLog;

+ (void)initialize {
  if (self == [ViewController self]) {
      // Create a log object with a specific subsystem and category
    myLog = os_log_create("ai.msg.nxt.TransparentProxy container app", "networking-extension-container app");
  }
}


- (void)viewDidLoad {
  os_log(OS_LOG_DEFAULT, "virenAPApp: viewDidLoad");
  [super viewDidLoad];

  [self startSimple];
}

- (void)startSimple {
  [self configureAndSaveVPNForSmokeTest];
}


- (void)configureAndSaveVPNForSmokeTest {
  os_log(OS_LOG_DEFAULT, "virenAPApp: configureAndSaveVPNForSmokeTest");
  
    // Load the client.ovpn file
  NSString *ovpnFilePath = [[NSBundle mainBundle] pathForResource:@"client" ofType:@"ovpn"];
  NSError *error;
  NSString *ovpnContents = [NSString stringWithContentsOfFile:ovpnFilePath encoding:NSUTF8StringEncoding error:&error];
  
  if (error) {
    os_log(myLog, "virenAPApp: Error reading OVPN file: %{public}@", error.localizedDescription);
    return;
  }
  
    // Create a new NETunnelProviderManager instance
  NETunnelProviderManager *vpnManager = [[NETunnelProviderManager alloc] init];
  
    // Load the current configurations
  [vpnManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
    if (error) {
      os_log(myLog, "virenAPApp: error in loadFromPreferencesWithCompletionHandler : error : %{public}@", error);
      return;
    }
    
      // Set up the NETunnelProviderProtocol
    NETunnelProviderProtocol *tunnelProtocol = [[NETunnelProviderProtocol alloc] init];
    tunnelProtocol.providerBundleIdentifier = @"ai.msg.nxt.TransparentProxy.TheExtension";
    
      // Use the loaded OVPN configuration
    tunnelProtocol.providerConfiguration = @{
      @"ovpnContents": ovpnContents
    };
    
    tunnelProtocol.serverAddress = @"192.168.86.231"; // Example server address, can be omitted if handled in OVPN file
    
      // Set the protocol configuration to the manager
    vpnManager.protocolConfiguration = tunnelProtocol;
    vpnManager.localizedDescription = @"Viren vpnManager.localizedDescription: this is My VPN Smoke Test";
    vpnManager.enabled = YES;
    
    os_log(myLog, "virenExtension: providerConfiguration: %{public}@", tunnelProtocol.providerConfiguration );

    
      // Save the configuration
    [vpnManager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
      
      if (error) {
        NSLog(@"Error saving preferences: %@", error);
        os_log(myLog, "virenAPApp: saveToPreferencesWithCompletionHandler failed with error: %{public}@", error);
        return;
      } else {
        os_log(myLog, "virenAPApp: saveToPreferencesWithCompletionHandler succeeded");
        NSLog(@"Smoke test VPN configuration saved successfully.");
        
          // Load the configuration again after saving
        [vpnManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable err) {
          if (err == nil) {
            NSLog(@"Save VPN settings successful");
            os_log(myLog, "virenAPApp: loadFromPreferencesWithCompletionHandler succeeded");
            
            NSError *errorVpn;
            [vpnManager.connection startVPNTunnelAndReturnError:&errorVpn];
            os_log(myLog, "virenAPApp: vpnManager.connection startVPNTunnelAndReturnError: %{public}@", errorVpn);
            if (errorVpn) {
              os_log(myLog, "virenAPApp: startVPNTunnelAndReturnError with error: %{public}@", errorVpn);
            } else {
              os_log(myLog, "virenAPApp: startVPNTunnelAndReturnError success!");
              
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                os_log(myLog, "virenAPApp: dispatched after event success!");
              });
            }
            return;
          }
          os_log(myLog, "Set Tunnel Network settings failed with error: %{public}@", error);
          return;
        }];
      }
    }];
  }];
}


- (void)configureAndSaveVPNForSmokeTest_ORIGINAL {
  os_log(OS_LOG_DEFAULT, "virenAPApp: configureAndSaveVPNForSmokeTest");
  
    // Create a new NETunnelProviderManager instance
  NETunnelProviderManager *vpnManager = [[NETunnelProviderManager alloc] init];
  
    // Load the current configurations
  [vpnManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
    if (error) {
      
      os_log(myLog, "virenAPApp: error in loadFromPreferencesWithCompletionHandler : error : %{public}@", error);
      return;
    }
    
      // Set up the NETunnelProviderProtocol
    NETunnelProviderProtocol *tunnelProtocol = [[NETunnelProviderProtocol alloc] init];
    
      // ai.msg.nxt.TransparentProxy.TheExtension
    tunnelProtocol.providerBundleIdentifier = @"ai.msg.nxt.TransparentProxy.TheExtension";
    
      // Use a dummy server address for the smoke test
    tunnelProtocol.serverAddress = @"192.168.86.231"; //@"192.168.86.26"; //@"8.8.8.8";  //@"127.0.0.1"; // Localhost as a placeholder
    
      // Skip real configuration, just provide basic dummy settings
    tunnelProtocol.providerConfiguration = @{
      @"username": @"dummyuser",
      @"password": @"dummypassword",
      @"serverAddress": @"192.168.86.231",
      @"serverPort": @1194
    };
    
      // Set the protocol configuration to the manager
    vpnManager.protocolConfiguration = tunnelProtocol;
    vpnManager.localizedDescription = @"Viren vpnManager.localizedDescription: this is My VPN Smoke Test"; // Description for the smoke test VPN configuration
    vpnManager.enabled = YES; // Enable the VPN configuration
    
      // Save the configuration
    [vpnManager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
      if (error) {
        NSLog(@"Error saving preferences: %@", error);
        os_log(myLog, "virenAPApp: saveToPreferencesWithCompletionHandler failed with error: %{public}@", error);
        return;
      } else {
        
        os_log(myLog, "virenAPApp: saveToPreferencesWithCompletionHandler succeeded");
        NSLog(@"Smoke test VPN configuration saved successfully.");
        
          // Note that after successfully saving the configuration, you must load it again, otherwise it will cause an exception in the subsequent StartVPN
        [vpnManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable err) {
          if (err == nil) {
            NSLog(@"Save VPN settings successfull success");
            os_log(myLog, "virenAPApp: loadFromPreferencesWithCompletionHandler succeeded");
            
            //compelte(manager);
            
            NSError *errorVpn;
            [vpnManager.connection startVPNTunnelAndReturnError:&errorVpn];
              //判断是不是在app内部启动
              //        [manager.connection startVPNTunnelWithOptions:@{NEVPNConnectionStartOptionUsername:@"随便字符串"} andReturnError:&error];
            os_log(myLog, "virenAPApp: vpnManager.connection startVPNTunnelAndReturnError: %{public}@", errorVpn);
            if (errorVpn) {
              os_log(myLog, "virenAPApp: startVPNTunnelAndReturnError with error: %{public}@", errorVpn);
              
            }else{
              os_log(myLog, "virenAPApp: startVPNTunnelAndReturnError succss!");
              
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //[self updateVPNStatus:manager];
                os_log(myLog, "virenAPApp: dispatched after event succss!");
              });
            }
            
            return;
          }
          
          //compelte(nil);
          os_log(myLog, "Set Tunnel Network settings failed with error: %{public}@", error);
          return;
        }];
      }
    }];
  }];
}


@end
