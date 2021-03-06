
#import "CPGraph.h"
#import "CPExceptions.h"
#import "CPPlot.h"
#import "CPPlotArea.h"
#import "CPPlotSpace.h"
#import "CPFill.h"
#import "CPAxisSet.h"
#import "CPAxis.h"

///	@cond
@interface CPGraph()

@property (nonatomic, readwrite, retain) NSMutableArray *plots;
@property (nonatomic, readwrite, retain) NSMutableArray *plotSpaces;

-(void)plotSpaceMappingDidChange:(NSNotification *)notif;

@end
///	@endcond

/**	@brief An abstract graph class.
 *	@todo More documentation needed 
 **/
@implementation CPGraph

/// @defgroup CPGraph CPGraph
/// @{

/**	@property axisSet
 *	@brief The axis set.
 **/
@synthesize axisSet;

/**	@property plotArea
 *	@brief The plot area.
 **/
@synthesize plotArea;

/**	@property fill
 *	@brief The background fill.
 **/
@synthesize fill;

/**	@property plots
 *	@brief An array of all plots associated with the graph.
 **/
@synthesize plots;

/**	@property plotSpaces
 *	@brief An array of all plot spaces associated with the graph.
 **/
@synthesize plotSpaces;

/**	@property defaultPlotSpace
 *	@brief The default plot space.
 **/
@dynamic defaultPlotSpace;

#pragma mark -
#pragma mark Init/Dealloc

-(id)initWithFrame:(CGRect)newFrame
{
	if ( self = [super initWithFrame:newFrame] ) {
		self.fill = nil;
		self.plots = [[NSMutableArray alloc] init];
        
        // Plot area
        self.plotArea = [(CPPlotArea *)[CPPlotArea alloc] initWithFrame:self.bounds];
        [self addSublayer:self.plotArea];
		
        // Plot spaces
		self.plotSpaces = [[NSMutableArray alloc] init];
        CPPlotSpace *newPlotSpace = [self newPlotSpace];
        [self addPlotSpace:newPlotSpace];
        [newPlotSpace release];
        
        // Axis set
        CPAxisSet *newAxisSet = [self newAxisSet];
        self.axisSet = newAxisSet;
        [newAxisSet release];
        		
		self.needsDisplayOnBoundsChange = YES;
	}
	return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

	[axisSet release];
	[plotArea release];
    [fill release];
	[plots release];
	[plotSpaces release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Retrieving Plots

/**	@brief Makes all plots reload their data.
 **/
-(void)reloadData
{
    [[self allPlots] makeObjectsPerformSelector:@selector(reloadData)];
}

/**	@brief All plots associated with the graph.
 *	@return An array of all plots associated with the graph. 
 **/
-(NSArray *)allPlots 
{    
	return [NSArray arrayWithArray:self.plots];
}

/**	@brief Gets the plot at the given index in the plot array.
 *	@param index An index within the bounds of the plot array.
 *	@return The plot at the given index.
 **/
-(CPPlot *)plotAtIndex:(NSUInteger)index
{
    return [self.plots objectAtIndex:index];
}

/**	@brief Gets the plot with the given identifier.
 *	@param identifier A plot identifier.
 *	@return The plot with the given identifier.
 **/
-(CPPlot *)plotWithIdentifier:(id <NSCopying>)identifier 
{
	for (CPPlot *plot in self.plots) {
        if ( [[plot identifier] isEqual:identifier] ) return plot;
	}
    return nil;
}

#pragma mark -
#pragma mark Organizing Plots

/**	@brief Add a plot to the default plot space.
 *	@param plot The plot.
 **/
-(void)addPlot:(CPPlot *)plot
{
	[self addPlot:plot toPlotSpace:self.defaultPlotSpace];
}

/**	@brief Add a plot to the given plot space.
 *	@param plot The plot.
 *	@param space The plot space.
 **/
-(void)addPlot:(CPPlot *)plot toPlotSpace:(CPPlotSpace *)space
{
	if (plot) {
		[self.plots addObject:plot];
		plot.plotSpace = space;
		[space addSublayer:plot];		
		[self setNeedsDisplay];
	}
}

/**	@brief Remove a plot from the graph.
 *	@param plot The plot to remove.
 **/
-(void)removePlot:(CPPlot *)plot
{
    if ( [self.plots containsObject:plot] ) {
		[self.plots removeObject:plot];
        plot.plotSpace = nil;
        [plot removeFromSuperlayer];		
		[self setNeedsDisplay];
    }
    else {
        [NSException raise:CPException format:@"Tried to remove CPPlot which did not exist."];
    }
}

/**	@brief Add a plot to the default plot space at the given index in the plot array.
 *	@param plot The plot.
 *	@param index An index within the bounds of the plot array.
 **/
-(void)insertPlot:(CPPlot* )plot atIndex:(NSUInteger)index 
{
	[self insertPlot:plot atIndex:index intoPlotSpace:self.defaultPlotSpace];
}

/**	@brief Add a plot to the given plot space at the given index in the plot array.
 *	@param plot The plot.
 *	@param index An index within the bounds of the plot array.
 *	@param space The plot space.
 **/
-(void)insertPlot:(CPPlot* )plot atIndex:(NSUInteger)index intoPlotSpace:(CPPlotSpace *)space
{
	if (plot) {
		[self.plots insertObject:plot atIndex:index];
		plot.plotSpace = space;
		[space addSublayer:plot];
		[self setNeedsDisplay];
	}
}

/**	@brief Remove a plot from the graph.
 *	@param identifier The identifier of the plot to remove.
 **/
-(void)removePlotWithIdentifier:(id <NSCopying>)identifier 
{
	CPPlot* plotToRemove = [self plotWithIdentifier:identifier];
	if (plotToRemove) {
		plotToRemove.plotSpace = nil;
		[plotToRemove removeFromSuperlayer];
		[self.plots removeObjectIdenticalTo:plotToRemove];
		[self setNeedsDisplay];
	}
}

#pragma mark -
#pragma mark Retrieving Plot Spaces

-(CPPlotSpace *)defaultPlotSpace {
    return ( self.plotSpaces.count > 0 ? [self.plotSpaces objectAtIndex:0] : nil );
}

/**	@brief All plot spaces associated with the graph.
 *	@return An array of all plot spaces associated with the graph. 
 **/
-(NSArray *)allPlotSpaces
{
	return [NSArray arrayWithArray:self.plotSpaces];
}

/**	@brief Gets the plot space at the given index in the plot space array.
 *	@param index An index within the bounds of the plot space array.
 *	@return The plot space at the given index.
 **/
-(CPPlotSpace *)plotSpaceAtIndex:(NSUInteger)index
{
	return ( self.plotSpaces.count > index ? [self.plotSpaces objectAtIndex:index] : nil );
}

/**	@brief Gets the plot space with the given identifier.
 *	@param identifier A plot space identifier.
 *	@return The plot space with the given identifier.
 **/
-(CPPlotSpace *)plotSpaceWithIdentifier:(id <NSCopying>)identifier
{
	for (CPPlotSpace *plotSpace in self.plotSpaces) {
        if ( [[plotSpace identifier] isEqual:identifier] ) return plotSpace;
	}
    return nil;	
}

#pragma mark -
#pragma mark Organizing Plot Spaces

/**	@brief Add a plot space to the graph.
 *	@param space The plot space.
 **/
-(void)addPlotSpace:(CPPlotSpace *)space
{
	space.frame = self.plotArea.bounds;
	[self.plotSpaces addObject:space];
	[self.plotArea addSublayer:space];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(plotSpaceMappingDidChange:) name:CPPlotSpaceCoordinateMappingDidChangeNotification object:space];
}

/**	@brief Remove a plot space from the graph.
 *	@param plotSpace The plot space.
 **/
-(void)removePlotSpace:(CPPlotSpace *)plotSpace
{
	if ( [self.plotSpaces containsObject:plotSpace] ) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:CPPlotSpaceCoordinateMappingDidChangeNotification object:plotSpace];
		[self.plotSpaces removeObject:plotSpace];
        [plotSpace removeFromSuperlayer];
        for ( CPAxis *axis in self.axisSet.axes ) {
            if ( axis.plotSpace == plotSpace ) axis.plotSpace = nil;
        }
    }
    else {
        [NSException raise:CPException format:@"Tried to remove CPPlotSpace which did not exist."];
    }
}


#pragma mark -
#pragma mark Coordinate Changes in Plot Spaces

-(void)plotSpaceMappingDidChange:(NSNotification *)notif 
{
    [self setNeedsLayout];
    [self.axisSet relabelAxes];
    for ( CPPlot *plot in self.plots ) {
        [plot setNeedsDisplay];
    }
}

#pragma mark -
#pragma mark Axis Set

-(void)setAxisSet:(CPAxisSet *)newSet
{
    if ( newSet != axisSet ) {
		[axisSet removeFromSuperlayer];
		[newSet retain];
        [axisSet release];
        axisSet = newSet;
        if ( axisSet ) {
			axisSet.graph = self;
			[self addSublayer:axisSet];	
		}
		[self setNeedsDisplay];
    }
}

#pragma mark -
#pragma mark Drawing

-(void)renderAsVectorInContext:(CGContextRef)theContext
{
	[self.fill fillRect:self.bounds inContext:theContext];
}

#pragma mark -
#pragma mark Layout

+(CGFloat)defaultZPosition 
{
	return CPDefaultZPositionGraph;
}

-(void)layoutSublayers 
{
	[super layoutSublayers];
	
    if ( self.axisSet ) {
        // Set the bounds so that the axis set coordinates coincide with the 
        // plot area drawing coordinates.
        CGRect axisSetBounds = self.bounds;
        axisSetBounds.origin = [self convertPoint:self.bounds.origin toLayer:self.plotArea];
		
		CPAxisSet *theAxisSet = self.axisSet;
        theAxisSet.bounds = axisSetBounds;
        theAxisSet.anchorPoint = CGPointZero;
        theAxisSet.position = self.bounds.origin;
    }
}

#pragma mark -
#pragma mark Accessors

-(void)setFill:(CPFill *)newFill 
{
    if ( newFill != fill ) {
		[newFill retain];
        [fill release];
        fill = newFill;
        [self setNeedsDisplay];
    }
}
///	@}

@end

///	@brief CPGraph abstract methods—must be overridden by subclasses
@implementation CPGraph(AbstractFactoryMethods)

/// @addtogroup CPGraph
/// @{

/**	@brief Creates a new plot space for the graph.
 *	@return A new plot space.
 **/
-(CPPlotSpace *)newPlotSpace
{
	return nil;
}

/**	@brief Creates a new axis set for the graph.
 *	@return A new axis set.
 **/
-(CPAxisSet *)newAxisSet
{
	return nil;
}
///	@}

@end
