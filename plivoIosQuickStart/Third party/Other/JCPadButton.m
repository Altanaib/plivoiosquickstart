
#import "JCPadButton.h"
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Constants.h"

#define animationLength 0.15
#define IS_IOS6_OR_LOWER (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)

@interface JCPadButton()

@property (nonatomic, strong) UIView *selectedView;

- (void)setDefaultStyles;
- (void)prepareApperance;
- (void)performLayout;

@end

@implementation JCPadButton

#pragma mark -
#pragma mark - Init Methods
- (instancetype)initWithMainLabel:(NSString *)main subLabel:(NSString *)sub
{
    if (self = [super initWithFrame:CGRectMake(0, 0, heightCalculate(65), heightCalculate(65))])
    {
        [self setDefaultStyles];
        
        self.input = main;
        self.longPressInput = @"";
        self.accessibilityValue = [@"PhoneButton" stringByAppendingString:main];
        self.layer.borderWidth = 1.5f;
        self.mainLabel = ({
            UILabel *label = [self standardLabel];
            label.text = main;
            label.font = self.mainLabelFont;
            label.contentMode = UIViewContentModeTop;
            label;
        });
        self.subLabel = ({
            UILabel *label = [self standardLabel];
            label.attributedText = [[NSAttributedString alloc] initWithString:sub ?: @""
                                                                   attributes:@{NSFontAttributeName: self.subLabelFont, NSKernAttributeName: @2}];
            label;
        });
        
        self.selectedView = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
            view.alpha = 0.0f;
            view.backgroundColor = self.selectedColor;
            view;
        });
    }
    return self;
}

- (instancetype)initWithInput:(NSString *)input iconView:(UIView *)iconView subLabel:(NSString *)sub
{
    if (self = [self initWithMainLabel:@"" subLabel:sub]) {
        self.input = input;
        self.iconView = iconView;
        self.iconView.userInteractionEnabled = NO;
    }
    return self;
}

#pragma mark -
#pragma mark - Lifecycle Methods
- (void)layoutSubviews
{
    [super layoutSubviews];
    [self prepareApperance];
    [self performLayout];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [self prepareApperance];
}

#pragma mark -
#pragma mark - Helper Methods
- (void)setDefaultStyles
{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"Keypad Enabled"])
    {
        self.borderColor = [UIColor whiteColor];
        self.selectedColor = [UIColor lightGrayColor];
        self.textColor = [UIColor whiteColor];
        self.hightlightedTextColor = [UIColor blackColor];

    }
    else
    {
        self.borderColor = [UIColor blackColor];
        self.selectedColor = [UIColor lightGrayColor];
        self.textColor = [UIColor blackColor];
        self.hightlightedTextColor = [UIColor blackColor];

    }

	static NSString* fontName = @"HelveticaNeue-Thin";
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		if (IS_IOS6_OR_LOWER) {
			fontName = @"HelveticaNeue";
		}
	});
	
    self.mainLabelFont = [UIFont systemFontOfSize:heightCalculate(32) weight:UIFontWeightThin];
    self.subLabelFont = [UIFont systemFontOfSize:heightCalculate(10) weight:UIFontWeightThin];

}

- (void)prepareApperance
{
    self.selectedView.backgroundColor = self.selectedColor;
    self.layer.borderColor = [self.borderColor CGColor];
    self.mainLabel.textColor = self.textColor;
    self.mainLabel.highlightedTextColor = self.hightlightedTextColor;
    self.subLabel.textColor = self.textColor;
    self.subLabel.highlightedTextColor = self.hightlightedTextColor;
}

- (void)performLayout
{
    self.selectedView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    [self addSubview:self.selectedView];
    
    if (self.subLabel.text.length)
        self.iconView.frame = CGRectMake(0, self.frame.size.height / 5, self.frame.size.width, self.frame.size.height/1.5);
    else
        self.iconView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    [self addSubview:self.iconView];
    
    self.mainLabel.frame = CGRectMake(0, self.frame.size.height / 5, self.frame.size.width, self.frame.size.height/2.5);
    [self addSubview:self.mainLabel];
	
	if(self.tag == 0)
	{
		CGPoint center = self.mainLabel.center;
		center.y = self.bounds.size.height / 2 - 1;
		self.mainLabel.center = center;
	}
    
    self.subLabel.frame = CGRectMake(0, self.mainLabel.frame.origin.y + self.mainLabel.frame.size.height + 3, self.frame.size.width, heightCalculate(10));
    [self addSubview:self.subLabel];
}

#pragma mark -
#pragma mark - Button Overides
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];

    AudioServicesPlaySystemSound(1200);

    __weak JCPadButton *weakSelf = self;
    [UIView animateWithDuration:animationLength delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        weakSelf.selectedView.alpha = 1.0f;
        [weakSelf setHighlighted:YES];
    } completion:nil];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self fadeOut];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self fadeOut];
}

- (void)fadeOut
{
    __weak JCPadButton *weakSelf = self;
    [UIView animateWithDuration:animationLength
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        weakSelf.selectedView.alpha = 0.0f;
        [weakSelf setHighlighted:NO];
    } completion:nil];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];

    self.mainLabel.highlighted = highlighted;
    self.subLabel.highlighted = highlighted;
}

#pragma mark -
#pragma mark - Default View Methods
- (UILabel *)standardLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.textColor = [UIColor blackColor];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
	label.minimumScaleFactor = 1.0;
    
    return label;
}

@end

CGFloat const JCPadButtonHeight = 65.0;
CGFloat const JCPadButtonWidth = 65.0;
