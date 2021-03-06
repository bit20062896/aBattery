
#import "CPDarkGradientTheme.h"
#import "CPXYGraph.h"
#import "CPColor.h"
#import "CPGradient.h"
#import "CPFill.h"
#import "CPPlotArea.h"
#import "CPXYPlotSpace.h"
#import "CPUtilities.h"
#import "CPXYAxisSet.h"
#import "CPXYAxis.h"
#import "CPLineStyle.h"
#import "CPTextStyle.h"
#import "CPBorderedLayer.h"
#import "CPExceptions.h"

///	@cond
@interface CPDarkGradientTheme ()

-(void)applyThemeToAxis:(CPXYAxis *)axis usingMajorLineStyle:(CPLineStyle *)majorLineStyle andMinorLineStyle:(CPLineStyle *)minorLineStyle andTextStyle:(CPTextStyle *)textStyle;

@end
///	@endcond

#pragma mark -

/** @brief Creates a CPXYGraph instance formatted with dark gray gradient backgrounds and light gray lines.
 **/
@implementation CPDarkGradientTheme

/// @defgroup CPDarkGradientTheme CPDarkGradientTheme
/// @{

+(NSString *)name 
{
	return kCPDarkGradientTheme;
}

-(void)applyThemeToAxis:(CPXYAxis *)axis usingMajorLineStyle:(CPLineStyle *)majorLineStyle andMinorLineStyle:(CPLineStyle *)minorLineStyle andTextStyle:(CPTextStyle *)textStyle
{
	axis.axisLabelingPolicy = CPAxisLabelingPolicyFixedInterval;
    axis.majorIntervalLength = CPDecimalFromString(@"0.5");
    axis.constantCoordinateValue = CPDecimalFromString(@"0");
	axis.tickDirection = CPSignNone;
    axis.minorTicksPerInterval = 4;
    axis.majorTickLineStyle = majorLineStyle;
    axis.minorTickLineStyle = minorLineStyle;
    axis.axisLineStyle = majorLineStyle;
    axis.majorTickLength = 7.0f;
    axis.minorTickLength = 5.0f;
	axis.axisLabelTextStyle = textStyle; 
}

-(void)applyThemeToBackground:(CPXYGraph *)graph 
{
	CPColor *endColor = [CPColor colorWithGenericGray:0.1];
	CPGradient *graphGradient = [CPGradient gradientWithBeginningColor:endColor endingColor:endColor];
	graphGradient = [graphGradient addColorStop:[CPColor colorWithGenericGray:0.2] atPosition:0.3];
	graphGradient = [graphGradient addColorStop:[CPColor colorWithGenericGray:0.3] atPosition:0.5];
	graphGradient = [graphGradient addColorStop:[CPColor colorWithGenericGray:0.2] atPosition:0.6];
	graphGradient.angle = 90.0f;
	graph.fill = [CPFill fillWithGradient:graphGradient];
}

-(void)applyThemeToPlotArea:(CPPlotArea *)plotArea 
{
	CPGradient *gradient = [CPGradient gradientWithBeginningColor:[CPColor colorWithGenericGray:0.1] endingColor:[CPColor colorWithGenericGray:0.3]];
    gradient.angle = 90.0;
	plotArea.fill = [CPFill fillWithGradient:gradient]; 
}

-(void)applyThemeToAxisSet:(CPXYAxisSet *)axisSet {
	CPLineStyle *borderLineStyle = [CPLineStyle lineStyle];
    borderLineStyle.lineColor = [CPColor colorWithGenericGray:0.2];
    borderLineStyle.lineWidth = 3.0f;
	
	CPBorderedLayer *borderedLayer = (CPBorderedLayer *)axisSet.overlayLayer;
	borderedLayer.borderLineStyle = borderLineStyle;
	borderedLayer.cornerRadius = 10.0f;
	axisSet.overlayLayerInsetX = -4.f;
	axisSet.overlayLayerInsetY = -4.f;
    
    CPLineStyle *majorLineStyle = [CPLineStyle lineStyle];
    majorLineStyle.lineCap = kCGLineCapSquare;
    majorLineStyle.lineColor = [CPColor colorWithGenericGray:0.5];
    majorLineStyle.lineWidth = 3.0f;
    
    CPLineStyle *minorLineStyle = [CPLineStyle lineStyle];
    minorLineStyle.lineCap = kCGLineCapSquare;
    minorLineStyle.lineColor = [CPColor darkGrayColor];
    minorLineStyle.lineWidth = 3.0f;
	
	CPTextStyle *whiteTextStyle = [[[CPTextStyle alloc] init] autorelease];
	whiteTextStyle.color = [CPColor whiteColor];
	whiteTextStyle.fontSize = 14.0;
	
    for (CPXYAxis *axis in axisSet.axes) {
        [self applyThemeToAxis:axis usingMajorLineStyle:majorLineStyle andMinorLineStyle:minorLineStyle andTextStyle:whiteTextStyle];
    }
}

///	@}

@end
