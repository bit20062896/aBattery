
#import "CPAxis.h"
#import "CPPlotSpace.h"
#import "CPUtilities.h"
#import "CPPlotRange.h"
#import "CPLineStyle.h"
#import "CPTextStyle.h"
#import "CPTextLayer.h"
#import "CPAxisLabel.h"
#import "CPPlatformSpecificCategories.h"
#import "CPUtilities.h"
#import "NSDecimalNumberExtensions.h"

///	@cond
@interface CPAxis ()

@property (nonatomic, readwrite, assign) BOOL needsRelabel;

-(void)tickLocationsBeginningAt:(NSDecimal)beginNumber increasing:(BOOL)increasing majorTickLocations:(NSSet **)newMajorLocations minorTickLocations:(NSSet **)newMinorLocations;
-(NSDecimal)nextLocationFromCoordinateValue:(NSDecimal)coord increasing:(BOOL)increasing interval:(NSDecimal)interval;

-(NSSet *)filteredTickLocations:(NSSet *)allLocations;

@end
///	@endcond

/**	@brief An abstract axis class.
 **/
@implementation CPAxis

/// @defgroup CPAxis CPAxis
/// @{

// Axis

/**	@property axisLineStyle
 *  @brief The line style for the axis line.
 *	If nil, the line is not drawn.
 **/
@synthesize axisLineStyle;

/**	@property coordinate
 *	@brief The axis coordinate.
 **/
@synthesize coordinate;

/**	@property fixedPoint
 *	@brief The axis origin.
 **/
@synthesize fixedPoint;

/**	@property tickDirection
 *	@brief The tick direction.
 **/
@synthesize tickDirection;

// Plot space

/**	@property plotSpace
 *	@brief The plot space for the axis.
 **/
@synthesize plotSpace;

// Labels

/**	@property axisLabelingPolicy
 *	@brief The axis labeling policy.
 **/
@synthesize axisLabelingPolicy;

/**	@property axisLabelOffset
 *	@brief The offset distance between the tick marks and labels.
 **/
@synthesize axisLabelOffset;

/**	@property axisLabelTextStyle
 *	@brief The text style used to draw the label text.
 **/
@synthesize axisLabelTextStyle;

/**	@property tickLabelFormatter
 *	@brief The number formatter used to format the label text.
 *  If you need a non-numerical label, such as a date, you can use a formatter than turns
 *  the numerical plot coordinate into a string (eg 'Jan 10, 2010'). 
 *  The CPTimeFormatter is useful for this purpose.
 **/
@synthesize tickLabelFormatter;

/**	@property axisLabels
 *	@brief The set of axis labels.
 **/
@synthesize axisLabels;

/**	@property needsRelabel
 *	@brief If YES, the axis needs to be relabeled before the layer content is drawn.
 **/
@synthesize needsRelabel;

/**	@property labelExclusionRanges
 *	@brief An array of CPPlotRange objects. Any tick marks and labels falling inside any of the ranges in the array will not be drawn.
 **/
@synthesize labelExclusionRanges;

/**	@property delegate
 *	@brief The axis delegate.
 **/
@synthesize delegate;

// Major ticks

/**	@property majorIntervalLength
 *	@brief The distance between major tick marks expressed in data coordinates.
 **/
@synthesize majorIntervalLength;

/**	@property majorTickLineStyle
 *  @brief The line style for the major tick marks.
 *	If nil, the major ticks are not drawn.
 **/
@synthesize majorTickLineStyle;

/**	@property majorTickLength
 *	@brief The length of the major tick marks.
 **/
@synthesize majorTickLength;

/**	@property majorTickLocations
 *	@brief A set of axis coordinates for all major tick marks.
 **/
@synthesize majorTickLocations;

// Minor ticks

/**	@property minorTicksPerInterval
 *	@brief The number of minor tick marks drawn in each major tick interval.
 **/
@synthesize minorTicksPerInterval;

/**	@property minorTickLineStyle
 *  @brief The line style for the minor tick marks.
 *	If nil, the minor ticks are not drawn.
 **/
@synthesize minorTickLineStyle;

/**	@property minorTickLength
 *	@brief The length of the minor tick marks.
 **/
@synthesize minorTickLength;

/**	@property minorTickLocations
 *	@brief A set of axis coordinates for all minor tick marks.
 **/
@synthesize minorTickLocations;

// Grid Lines

/**	@property majorGridLineStyle
 *  @brief The line style for the major grid lines.
 *	If nil, the major grid lines are not drawn.
 **/
@synthesize majorGridLineStyle;

/**	@property minorGridLineStyle
 *  @brief The line style for the minor grid lines.
 *	If nil, the minor grid lines are not drawn.
 **/
@synthesize minorGridLineStyle;

#pragma mark -
#pragma mark Init/Dealloc

-(id)initWithFrame:(CGRect)newFrame
{
	if ( self = [super initWithFrame:newFrame] ) {
		self.plotSpace = nil;
		self.majorTickLocations = [NSArray array];
		self.minorTickLocations = [NSArray array];
		self.minorTickLength = 3.f;
		self.majorTickLength = 5.f;
		self.axisLabelOffset = 2.f;
		self.axisLineStyle = [CPLineStyle lineStyle];
		self.majorTickLineStyle = [CPLineStyle lineStyle];
		self.minorTickLineStyle = [CPLineStyle lineStyle];
		self.fixedPoint = [[NSDecimalNumber zero] decimalValue];
		self.majorIntervalLength = [[NSDecimalNumber one] decimalValue];
		self.minorTicksPerInterval = 1;
		self.coordinate = CPCoordinateX;
		self.axisLabelingPolicy = CPAxisLabelingPolicyFixedInterval;
		self.axisLabelTextStyle = [[[CPTextStyle alloc] init] autorelease];
		NSNumberFormatter *newFormatter = [[NSNumberFormatter alloc] init];
		newFormatter.maximumFractionDigits = 1; 
        newFormatter.minimumFractionDigits = 1;
        self.tickLabelFormatter = newFormatter;
		[newFormatter release];
		self.axisLabels = [NSSet set];
        self.tickDirection = CPSignNone;
        self.needsRelabel = YES;
		self.labelExclusionRanges = nil;
		self.delegate = nil;
	}
	return self;
}

-(void)dealloc
{
	[plotSpace release];	
	[majorTickLocations release];
	[minorTickLocations release];
	[axisLineStyle release];
	[majorTickLineStyle release];
	[minorTickLineStyle release];
    [majorGridLineStyle release];
    [minorGridLineStyle release];
	[tickLabelFormatter release];
	[axisLabels release];
	[axisLabelTextStyle release];
	[labelExclusionRanges release];
	
	self.delegate = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Ticks

-(NSDecimal)nextLocationFromCoordinateValue:(NSDecimal)coord increasing:(BOOL)increasing interval:(NSDecimal)interval
{
	if ( increasing ) {
		return CPDecimalAdd(coord, interval);
	} else {
		return CPDecimalSubtract(coord, interval);
	}
}

-(void)tickLocationsBeginningAt:(NSDecimal)beginNumber increasing:(BOOL)increasing majorTickLocations:(NSSet **)newMajorLocations minorTickLocations:(NSSet **)newMinorLocations
{
	NSMutableSet *majorLocations = [NSMutableSet set];
	NSMutableSet *minorLocations = [NSMutableSet set];
	NSDecimal majorInterval = self.majorIntervalLength;
	NSDecimal coord = beginNumber;
	CPPlotRange *range = [self.plotSpace plotRangeForCoordinate:self.coordinate];
	
	while ( (increasing && CPDecimalLessThanOrEqualTo(coord, range.end)) || (!increasing && CPDecimalGreaterThanOrEqualTo(coord, range.location)) ) {
		
		// Major tick
		if ( CPDecimalLessThanOrEqualTo(coord, range.end) && CPDecimalGreaterThanOrEqualTo(coord, range.location) ) {
			[majorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:coord]];
		}
		
		// Minor ticks
		if ( self.minorTicksPerInterval > 0 ) {
			NSDecimal minorInterval = CPDecimalDivide(majorInterval, CPDecimalFromInt(self.minorTicksPerInterval+1));
			NSDecimal minorCoord;
			minorCoord = [self nextLocationFromCoordinateValue:coord increasing:increasing interval:minorInterval];
			for ( NSUInteger minorTickIndex = 0; minorTickIndex < self.minorTicksPerInterval; minorTickIndex++) {
				if ( CPDecimalLessThanOrEqualTo(minorCoord, range.end) && CPDecimalGreaterThanOrEqualTo(minorCoord, range.location)) {
					[minorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:minorCoord]];
				}
				minorCoord = [self nextLocationFromCoordinateValue:minorCoord increasing:increasing interval:minorInterval];
			}
		}
		
		coord = [self nextLocationFromCoordinateValue:coord increasing:increasing interval:majorInterval];
	}
	*newMajorLocations = majorLocations;
	*newMinorLocations = minorLocations;
}


#pragma mark -
#pragma mark Labels

/**	@brief Creates new axis labels at the given locations.
 *	@param locations An array of NSDecimalNumber label locations.
 *	@return An array of CPAxisLabels positioned at the given locations.
 **/
-(NSArray *)newAxisLabelsAtLocations:(NSArray *)locations
{
    NSMutableArray *newLabels = [[NSMutableArray alloc] initWithCapacity:locations.count];
	for ( NSDecimalNumber *tickLocation in locations ) {
        NSString *labelString = [self.tickLabelFormatter stringForObjectValue:tickLocation];
        CPAxisLabel *newLabel = [[CPAxisLabel alloc] initWithText:labelString textStyle:self.axisLabelTextStyle];
        newLabel.tickLocation = [tickLocation decimalValue];
        newLabel.offset = self.axisLabelOffset + self.majorTickLength;
        [newLabels addObject:newLabel];
        [newLabel release];
	}
	return newLabels;
}

/**	@brief Marks the receiver as needing to update the labels before the content is next drawn.
 **/
-(void)setNeedsRelabel
{
    self.needsRelabel = YES;
}

/**	@brief Updates the axis labels.
 **/
-(void)relabel
{
    if (!self.needsRelabel) return;
	if (!self.plotSpace) return;
	if ( self.delegate && ![self.delegate axisShouldRelabel:self] ) {
        self.needsRelabel = NO;
        return;
    }
	
	NSMutableSet *allNewMajorLocations = [NSMutableSet set];
	NSMutableSet *allNewMinorLocations = [NSMutableSet set];
	NSSet *newMajorLocations, *newMinorLocations;
	
	switch (self.axisLabelingPolicy) {
		case CPAxisLabelingPolicyNone:
            // Assume locations are set by user
            allNewMajorLocations = [[self.majorTickLocations mutableCopy] autorelease];
            allNewMinorLocations = [[self.minorTickLocations mutableCopy] autorelease];
			break;
		case CPAxisLabelingPolicyFixedInterval:
			// Add ticks in negative direction
			[self tickLocationsBeginningAt:self.fixedPoint increasing:NO majorTickLocations:&newMajorLocations minorTickLocations:&newMinorLocations];
			[allNewMajorLocations unionSet:newMajorLocations];  
			[allNewMinorLocations unionSet:newMinorLocations];  
			
			// Add ticks in positive direction
			[self tickLocationsBeginningAt:self.fixedPoint increasing:YES majorTickLocations:&newMajorLocations minorTickLocations:&newMinorLocations];
			[allNewMajorLocations unionSet:newMajorLocations];
			[allNewMinorLocations unionSet:newMinorLocations];
			
			break;
        case CPAxisLabelingPolicyAutomatic:
			// TODO: automatic labeling policy
			break;
		case CPAxisLabelingPolicyLogarithmic:
			// TODO: logarithmic labeling policy
			break;
	}
	
    if ( self.axisLabelingPolicy != CPAxisLabelingPolicyNone ) {
        // Filter and set tick locations	
        self.majorTickLocations = [self filteredMajorTickLocations:allNewMajorLocations];
        self.minorTickLocations = [self filteredMinorTickLocations:allNewMinorLocations];
        
        // Label ticks
        NSArray *newLabels = [self newAxisLabelsAtLocations:self.majorTickLocations.allObjects];
        self.axisLabels = [NSSet setWithArray:newLabels];
        [newLabels release];
    }

    self.needsRelabel = NO;
	
	[self.delegate axisDidRelabel:self];
}

-(NSSet *)filteredTickLocations:(NSSet *)allLocations 
{
	NSMutableSet *filteredLocations = [allLocations mutableCopy];
	for ( CPPlotRange *range in self.labelExclusionRanges ) {
		for ( NSDecimalNumber *location in allLocations ) {
			if ( [range contains:[location decimalValue]] ) [filteredLocations removeObject:location];
		}
	}
	return [filteredLocations autorelease];
}

/**	@brief Removes any major ticks falling inside the label exclusion ranges from the set of tick locations.
 *	@param allLocations A set of major tick locations.
 *	@return The filted set.
 **/
-(NSSet *)filteredMajorTickLocations:(NSSet *)allLocations
{
	return [self filteredTickLocations:allLocations];
}

/**	@brief Removes any minor ticks falling inside the label exclusion ranges from the set of tick locations.
 *	@param allLocations A set of minor tick locations.
 *	@return The filted set.
 **/
-(NSSet *)filteredMinorTickLocations:(NSSet *)allLocations
{
	return [self filteredTickLocations:allLocations];
}

#pragma mark -
#pragma mark Sublayer Layout

+(CGFloat)defaultZPosition 
{
	return CPDefaultZPositionAxis;
}

-(void)layoutSublayers 
{
	if ( self.needsRelabel ) [self relabel];
	
    for ( CPAxisLabel *label in self.axisLabels ) {
        CGPoint tickBasePoint = [self viewPointForCoordinateDecimalNumber:label.tickLocation];
        [label positionRelativeToViewPoint:tickBasePoint forCoordinate:OrthogonalCoordinate(self.coordinate) inDirection:self.tickDirection];
    }
}

#pragma mark -
#pragma mark Accessors

-(void)setAxisLabels:(NSSet *)newLabels 
{
    if ( newLabels != axisLabels ) {
        for ( CPAxisLabel *label in axisLabels ) {
            [label removeFromSuperlayer];
        }
		
		[newLabels retain];
        [axisLabels release];
        axisLabels = newLabels;

        for ( CPAxisLabel *label in axisLabels ) {
            [self addSublayer:label];
        }
        		
		[self setNeedsDisplay];		
	}
}

-(void)setAxisLabelTextStyle:(CPTextStyle *)newStyle 
{
	if ( newStyle != axisLabelTextStyle ) {
		[axisLabelTextStyle release];
		axisLabelTextStyle = [newStyle copy];
		[self setNeedsLayout];
	}
}

-(void)setLabelExclusionRanges:(NSArray *)ranges {
	if ( ranges != labelExclusionRanges ) {
		[labelExclusionRanges release];
		labelExclusionRanges = [ranges retain];
		[self setNeedsRelabel];
	}
}

-(void)setNeedsRelabel:(BOOL)newNeedsRelabel 
{
    if (newNeedsRelabel != needsRelabel) {
        needsRelabel = newNeedsRelabel;
        if ( needsRelabel ) {
            [self setNeedsLayout];
        }
    }
}

-(void)setMajorTickLocations:(NSSet *)newLocations 
{
    if ( newLocations != majorTickLocations ) {
        [majorTickLocations release];
        majorTickLocations = [newLocations retain];
		[self setNeedsDisplay];		
        [self setNeedsRelabel];
    }
}

-(void)setMinorTickLocations:(NSSet *)newLocations 
{
    if ( newLocations != majorTickLocations ) {
        [minorTickLocations release];
        minorTickLocations = [newLocations retain];
		[self setNeedsDisplay];		
        [self setNeedsRelabel];
    }
}

-(void)setMajorTickLength:(CGFloat)newLength 
{
    if ( newLength != majorTickLength ) {
        majorTickLength = newLength;
        [self setNeedsDisplay];
    }
}

-(void)setMinorTickLength:(CGFloat)newLength 
{
    if ( newLength != minorTickLength ) {
        minorTickLength = newLength;
        [self setNeedsDisplay];
    }
}

-(void)setAxisLabelOffset:(CGFloat)newOffset 
{
    if ( newOffset != axisLabelOffset ) {
        axisLabelOffset = newOffset;
		[self setNeedsLayout];
    }
}

-(void)setPlotSpace:(CPPlotSpace *)newSpace 
{
    if ( newSpace != plotSpace ) {
        [plotSpace release];
        plotSpace = [newSpace retain];
        self.needsRelabel = YES;
    }
}

-(void)setCoordinate:(CPCoordinate)newCoordinate 
{
    if (newCoordinate != coordinate) {
        coordinate = newCoordinate;
        self.needsRelabel = YES;
    }
}

-(void)setAxisLineStyle:(CPLineStyle *)newLineStyle 
{
    if ( newLineStyle != axisLineStyle ) {
        [axisLineStyle release];
        axisLineStyle = [newLineStyle copy];
		if (axisLineStyle != nil){
			[self setNeedsDisplay];			
		}
    }
}

-(void)setMajorTickLineStyle:(CPLineStyle *)newLineStyle 
{
    if ( newLineStyle != majorTickLineStyle ) {
        [majorTickLineStyle release];
        majorTickLineStyle = [newLineStyle copy];
        [self setNeedsDisplay];
    }
}

-(void)setMinorTickLineStyle:(CPLineStyle *)newLineStyle 
{
    if ( newLineStyle != minorTickLineStyle ) {
        [minorTickLineStyle release];
        minorTickLineStyle = [newLineStyle copy];
        [self setNeedsDisplay];
    }
}

-(void)setFixedPoint:(NSDecimal)newFixedPoint 
{
	if (CPDecimalEquals(fixedPoint, newFixedPoint)) {
		return;
	}
	fixedPoint = newFixedPoint;
	self.needsRelabel = YES;
}

-(void)setMajorIntervalLength:(NSDecimal)newIntervalLength 
{
	if (CPDecimalEquals(majorIntervalLength, newIntervalLength)) {
		return;
	}
	majorIntervalLength = newIntervalLength;
	self.needsRelabel = YES;
}

-(void)setMinorTicksPerInterval:(NSUInteger)newMinorTicksPerInterval 
{
    if (newMinorTicksPerInterval != minorTicksPerInterval) {
        minorTicksPerInterval = newMinorTicksPerInterval;
        self.needsRelabel = YES;
    }
}

-(void)setAxisLabelingPolicy:(CPAxisLabelingPolicy)newPolicy 
{
    if (newPolicy != axisLabelingPolicy) {
        axisLabelingPolicy = newPolicy;
        self.needsRelabel = YES;
    }
}

-(void)setTickLabelFormatter:(NSNumberFormatter *)newTickLabelFormatter 
{
    if ( newTickLabelFormatter != tickLabelFormatter ) {
        [tickLabelFormatter release];
        tickLabelFormatter = [newTickLabelFormatter retain];
        self.needsRelabel = YES;
    }
}

-(void)setTickDirection:(CPSign)newDirection 
{
    if (newDirection != tickDirection) {
        tickDirection = newDirection;
		[self setNeedsLayout];
    }
}

///	@}

@end

///	@brief CPAxis abstract methods—must be overridden by subclasses
@implementation CPAxis(AbstractMethods)

/// @addtogroup CPAxis
/// @{

/**	@brief Converts a position on the axis to drawing coordinates.
 *	@param coordinateDecimalNumber The axis value in data coordinate space.
 *	@return The drawing coordinates of the point.
 **/
-(CGPoint)viewPointForCoordinateDecimalNumber:(NSDecimal)coordinateDecimalNumber
{
	return CGPointMake(0.0f, 0.0f);
}

///	@}

@end
