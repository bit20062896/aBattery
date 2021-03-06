
#import "CPTextLayer.h"
#import "CPTextStyle.h"
#import "CPPlatformSpecificFunctions.h"
#import "CPColor.h"
#import "CPColorSpace.h"
#import "CPPlatformSpecificCategories.h"
#import "CPUtilities.h"

CGFloat kCPTextLayerMarginWidth = 1.0f;

/**	@brief A Core Animation layer that displays a single line of text drawn in a uniform style.
 **/
@implementation CPTextLayer

/**	@property text
 *	@brief The text to display.
 **/
@synthesize text;

/**	@property textStyle
 *	@brief The text style used to draw the text.
 **/
@synthesize textStyle;

#pragma mark -
#pragma mark Initialization and teardown

/** @brief Initializes a newly allocated CPTextLayer object with the provided text and style.
 *  @param newText The text to display.
 *  @param newStyle The text style used to draw the text.
 *  @return The initialized CPTextLayer object.
 **/
-(id)initWithText:(NSString *)newText style:(CPTextStyle *)newStyle
{
	if (self = [super initWithFrame:CGRectZero]) {	
		self.needsDisplayOnBoundsChange = NO;
		self.textStyle = newStyle;
		self.text = newText;
		[self sizeToFit];
	}
	
	return self;
}

/** @brief Initializes a newly allocated CPTextLayer object with the provided text and the default text style.
 *  @param newText The text to display.
 *  @return The initialized CPTextLayer object.
 **/
-(id)initWithText:(NSString *)newText
{
	return [self initWithText:newText style:[CPTextStyle textStyle]];
}

-(void)dealloc 
{
	[textStyle release];
	[text release];
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors

-(void)setText:(NSString *)newValue
{
	if ( text == newValue ) return;	
	[text release];
	text = [newValue copy];
	[self sizeToFit];
}

-(void)setTextStyle:(CPTextStyle *)newStyle 
{
	if ( newStyle != textStyle ) {
		[textStyle release];
		textStyle = [newStyle retain];
		[self sizeToFit];
	}
}

#pragma mark -
#pragma mark Layout

/**	@brief Resizes the layer to fit its contents leaving a narrow margin on all four sides.
 **/
-(void)sizeToFit
{	
	if ( self.text == nil ) return;
	CGSize textSize = [self.text sizeWithStyle:textStyle];

	// Add small margin
	textSize.width += 2 * kCPTextLayerMarginWidth;
	textSize.height += 2 * kCPTextLayerMarginWidth;
	
	CGRect newBounds = self.bounds;
	newBounds.size = textSize;
	self.bounds = newBounds;
	[self setNeedsDisplay];
}

#pragma mark -
#pragma mark Drawing of text

-(void)renderAsVectorInContext:(CGContextRef)context
{
#if defined(TARGET_IPHONE_SIMULATOR) || defined(TARGET_OS_IPHONE)
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, 0.0f, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0f, -1.0f);
#endif
	[self.text drawAtPoint:alignPointToUserSpace(context, CGPointMake(kCPTextLayerMarginWidth, kCPTextLayerMarginWidth)) withStyle:self.textStyle inContext:context];
#if defined(TARGET_IPHONE_SIMULATOR) || defined(TARGET_OS_IPHONE)
	CGContextRestoreGState(context);
#endif
}

@end
