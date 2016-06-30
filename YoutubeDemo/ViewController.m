//
//  ViewController.m
//  YoutubeDemo
//
//  Created by Jose Chen on 16/6/29.
//  Copyright © 2016年 Jose Chen. All rights reserved.
//

#import "ViewController.h"
#import "GTMOAuth2Authentication.h"
#import "GTMOAuth2ViewControllerTouch.h"

@interface ViewController ()
@property(nonatomic,strong) NSString *token;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    loginButton.frame = CGRectMake(20, 20, 80, 40);
    loginButton.backgroundColor = [UIColor redColor];
    [loginButton setTitle:@"login" forState:UIControlStateNormal];
    [loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:loginButton];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)login
{
    NSLog(@"进入google oauth登录页面");
    
    NSString *clientId=@"1088267263716-2frfetr0gep957ka86od8r3r9f8nn0bv.apps.googleusercontent.com";
    NSString *clientSecret=@"PoEzufb6s5tSEvGlwahyH_Dg";
    NSString *scope = @"https://www.googleapis.com/auth/youtube";
    
    
    SEL finishedSel = @selector(viewController:finishedWithAuth:error:);
    
    GTMOAuth2ViewControllerTouch *viewController;
    viewController = [GTMOAuth2ViewControllerTouch controllerWithScope:scope
                                                              clientID:clientId
                                                          clientSecret:clientSecret
                                                      keychainItemName:@"YoutubeOauth"
                                                              delegate:self
                                                      finishedSelector:finishedSel];
//    viewController.loginDelegate = self;
    
    NSString *html = @"<html><body bgcolor=white><div align=center>正在进入google登录页面...</div></body></html>";
    viewController.initialHTMLString = html;
    
    [self presentViewController:viewController animated:YES completion:nil];
}

-(void)viewController:(GTMOAuth2ViewControllerTouch *)viewController finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error{
    if (error!=nil) {
        //验证失败时，记录日志，并把弹出一个AlertView通知用户原因
        NSLog(@"Auth failed!");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:[error description] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        [self dismissViewControllerAnimated:YES completion:nil];
    }else{
        NSLog(@"Auth successed!");
        NSLog(@"Token: %@", [auth accessToken]);
        self.token = [auth accessToken];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
