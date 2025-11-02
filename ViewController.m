//
// ViewController.m
// BackScreen
//
// Created by Anonym on 01.11.25.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIButton *reloadButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.imageView = [[UIImageView alloc] init];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill; 
    self.imageView.clipsToBounds = YES;
    [self.view addSubview:self.imageView];

    [NSLayoutConstraint activateConstraints:@[
        [self.imageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.imageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.imageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.imageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];

    self.reloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.reloadButton.translatesAutoresizingMaskIntoConstraints = NO;

    [self.reloadButton setTitle:@"↻" forState:UIControlStateNormal];
    [self.reloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.reloadButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    self.reloadButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.reloadButton.layer.cornerRadius = 8;
    self.reloadButton.contentEdgeInsets = UIEdgeInsetsMake(10, 15, 10, 15);

    [self.reloadButton addTarget:self action:@selector(loadRandomCatImage) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.reloadButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.reloadButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20], 
        [self.reloadButton.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20]
    ]];

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.activityIndicator];

    [NSLayoutConstraint activateConstraints:@[
        [self.activityIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];

    [self loadRandomCatImage];
}

#pragma mark - API Call & Image Loading

- (void)loadRandomCatImage {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = nil;
        [self.activityIndicator startAnimating];
        self.reloadButton.enabled = NO;

        for (UIView *subview in self.view.subviews) {
            if ([subview isKindOfClass:[UILabel class]]) {
                [subview removeFromSuperview];
            }
        }
    });

    NSURL *apiURL = [NSURL URLWithString:@"https://api.thecatapi.com/v1/images/search"];

    [[[NSURLSession sharedSession] dataTaskWithURL:apiURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        if (error || !data) {
            NSLog(@"APIリクエストエラー: %@", error.localizedDescription);
            [self handleLoadingError:YES];
            return;
        }

        NSError *jsonError = nil;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

        if (jsonError || jsonArray.count == 0) {
            NSLog(@"JSONパースエラーまたはデータなし");
            [self handleLoadingError:YES];
            return;
        }

        NSDictionary *imageObject = jsonArray[0];
        NSString *imageURLString = imageObject[@"url"];

        if (imageURLString) {
            NSURL *imageURL = [NSURL URLWithString:imageURLString];

            [[[NSURLSession sharedSession] dataTaskWithURL:imageURL completionHandler:^(NSData *imageData, NSURLResponse *imageResponse, NSError *imageError) {

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.activityIndicator stopAnimating];
                    self.reloadButton.enabled = YES;

                    if (imageError || !imageData) {
                        NSLog(@"画像ダウンロードエラー: %@", imageError.localizedDescription);
                        [self handleLoadingError:NO];
                        return;
                    }

                    UIImage *catImage = [UIImage imageWithData:imageData];
                    if (catImage) {
                        self.imageView.image = catImage;
                    }
                });
            }] resume];
        } else {
            NSLog(@"画像URLが見つかりません。");
            [self handleLoadingError:YES];
        }
    }] resume];
}

- (void)handleLoadingError:(BOOL)isAPIError {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
        self.reloadButton.enabled = YES;

        for (UIView *subview in self.view.subviews) {
            if ([subview isKindOfClass:[UILabel class]]) {
                [subview removeFromSuperview];
            }
        }

        UILabel *errorLabel = [[UILabel alloc] init];
        errorLabel.translatesAutoresizingMaskIntoConstraints = NO;
        errorLabel.text = isAPIError ? @"API通信に失敗しました。" : @"画像のダウンロードに失敗しました。";
        errorLabel.textAlignment = NSTextAlignmentCenter;
        errorLabel.textColor = [UIColor systemRedColor];
        errorLabel.numberOfLines = 0;
        [self.view addSubview:errorLabel];

        [NSLayoutConstraint activateConstraints:@[
            [errorLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [errorLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
            [errorLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
            [errorLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20]
        ]];
    });
}

@end
