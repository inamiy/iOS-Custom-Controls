//
//  CustomSlider.m
//  Measures
//
//  Created by Michael Neuwert on 4/26/11.
//  Copyright 2011 Neuwert Media. All rights reserved.
//

#import "MNEValueTrackingSlider.h"

#pragma mark - Private UIView subclass rendering the popup showing slider value

@interface MNESliderValuePopupView : UIView  
//@property (nonatomic) float value;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, copy) NSString *text;
@property (nonatomic) float arrowOffset;
@end

@implementation MNESliderValuePopupView

//@synthesize value=_value;
@synthesize font=_font;
@synthesize text = _text;
@synthesize arrowOffset = _arrowOffset;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.font = [UIFont boldSystemFontOfSize:18];
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    
    // Set the fill color
	[[UIColor colorWithWhite:0 alpha:0.8] setFill];

    // Create the path for the rounded rectangle
    CGRect roundedRect = CGRectMake(self.bounds.origin.x + 3.0, self.bounds.origin.y, self.bounds.size.width - 6.0, floorf(self.bounds.size.height * 0.8));
    UIBezierPath *roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:6.0];
    
    // Create the arrow path
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];

	// Make sure the arrow offset is nice
	if (-self.arrowOffset + 1 > CGRectGetMidX(self.bounds) / 2)
		self.arrowOffset = -CGRectGetMidX(self.bounds) / 2 + 1;
	if (self.arrowOffset > CGRectGetMidX(self.bounds) / 2)
		self.arrowOffset = CGRectGetMidX(self.bounds) / 2 -1;

    CGFloat midX = CGRectGetMidX(self.bounds) + self.arrowOffset;
	
    CGPoint p0 = CGPointMake(midX, CGRectGetMaxY(self.bounds) - 1.0);
    [arrowPath moveToPoint:p0];
    [arrowPath addLineToPoint:CGPointMake((midX - 10.0), CGRectGetMaxY(roundedRect))];
    [arrowPath addLineToPoint:CGPointMake((midX + 10.0), CGRectGetMaxY(roundedRect))];
    [arrowPath closePath];
    
    // Attach the arrow path to the rounded rect
    [roundedRectPath appendPath:arrowPath];
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetShadow(context, CGSizeMake(0.0, 1.0), 2.0);
	CGContextSetShadowWithColor(context, CGSizeMake(0.0, 1.0), 2.5, [UIColor blackColor].CGColor);
    [roundedRectPath fill];

    // Draw the text
    if (self.text) {
        [[UIColor colorWithWhite:1 alpha:0.8] set];
        CGSize s = [_text sizeWithFont:self.font];
        CGFloat yOffset = (roundedRect.size.height - s.height) / 2;
        CGRect textRect = CGRectMake(roundedRect.origin.x, yOffset, roundedRect.size.width, s.height);
        
        [_text drawInRect:textRect 
                 withFont:self.font 
            lineBreakMode:UILineBreakModeWordWrap 
                alignment:UITextAlignmentCenter];    
    }
}

//- (void)setValue:(float)aValue {
//    _value = aValue;
//    self.text = [NSString stringWithFormat:@"%4.2f", _value];
//    [self setNeedsDisplay];
//}

@end

#pragma mark - MNEValueTrackingSlider implementations

@implementation MNEValueTrackingSlider

@synthesize valueFormat = _valueFormat;
@synthesize thumbRect;

#pragma mark - Private methods

- (void)_constructSlider {
    self.valueFormat = @"%4.2f";
    //self.valueFormat = @"%0.0f/%0.0f";
    
    valuePopupView = [[MNESliderValuePopupView alloc] initWithFrame:CGRectZero];
    valuePopupView.backgroundColor = [UIColor clearColor];
    valuePopupView.alpha = 0.0;
    [self addSubview:valuePopupView];
}

- (void)_fadePopupViewInAndOut:(BOOL)aFadeIn {
	[UIView animateWithDuration:0.5
						  delay:0.0
						options:UIViewAnimationOptionAllowUserInteraction
					 animations:^{
						 valuePopupView.alpha = (aFadeIn) ? 1.0 : 0.0;
					 } completion:nil];
}

- (void)_positionAndUpdatePopupView {
    CGRect _thumbRect = self.thumbRect;
    CGRect popupRect = CGRectOffset(_thumbRect, 0, -floorf(_thumbRect.size.height * 1.5));
	
    switch (_numberOfValueFormatSpecifiers) {
        case 1:
            valuePopupView.text = [NSString stringWithFormat:_valueFormat,self.value];
            break;
        case 2:
            valuePopupView.text = [NSString stringWithFormat:_valueFormat,self.value,self.maximumValue];
            break;
        default:
            valuePopupView.text = nil;
            break;
    }
    
    CGSize textSize = [valuePopupView.text sizeWithFont:valuePopupView.font];
    
    popupRect = CGRectInset(popupRect, -textSize.width/2.0, -textSize.height/2.0);
    
	if (popupRect.origin.x < 1)
		popupRect.origin.x = 1;
	else if (CGRectGetMaxX(popupRect) > CGRectGetMaxX(self.superview.bounds))
		popupRect.origin.x = CGRectGetMaxX(self.superview.bounds) - CGRectGetWidth(popupRect) - 1.0;
    
	valuePopupView.arrowOffset = CGRectGetMidX(_thumbRect) - CGRectGetMidX(popupRect);
    valuePopupView.frame = popupRect;
    //valuePopupView.value = (NSInteger)self.value;
    
    if (valuePopupView.text) {
        valuePopupView.hidden = NO;
        [valuePopupView setNeedsDisplay];
    }
    else {
        valuePopupView.hidden = YES;
    }
}

#pragma mark - Memory management

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _constructSlider];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _constructSlider];
    }
    return self;
}


#pragma mark - UIControl touch event tracking

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    // Fade in and update the popup view
    BOOL tracking = [super beginTrackingWithTouch:touch withEvent:event];
    if (tracking) {
        [self _positionAndUpdatePopupView];
        [self _fadePopupViewInAndOut:YES]; 
    }
    
    return tracking;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    // Update the popup view as slider knob is being moved
    BOOL tracking = [super continueTrackingWithTouch:touch withEvent:event];
    if (tracking) {
        [self _positionAndUpdatePopupView];
    }
    
    return tracking;
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    [super cancelTrackingWithEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    // Fade out the popoup view
    [super endTrackingWithTouch:touch withEvent:event];
    [self _positionAndUpdatePopupView];
    [self _fadePopupViewInAndOut:NO];
}

#pragma mark - Custom property accessors

- (void)setValueFormat:(NSString *)valueFormat {
    if (valueFormat != _valueFormat) {
        _valueFormat = [valueFormat copy];
        _numberOfValueFormatSpecifiers = [[valueFormat componentsSeparatedByString:@"%"] count]-1;
    }
}

- (CGRect)thumbRect {
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbR = [self thumbRectForBounds:self.bounds 
                                         trackRect:trackRect
                                             value:self.value];
    return thumbR;
}

@end
