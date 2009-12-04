#include "RegObserver.h"

#import "PSFSettingsWindowController.h"

void CommandIterationUpdate::Execute(ITKNS::Object *caller, const ITKNS::EventObject & event)
{
	OptimizerPointer optimizer = 
	dynamic_cast< OptimizerPointer >( caller );
		
	if(stopReg)
	{
		optimizer->StopOptimization();
	}
	
	Execute( (const ITKNS::Object *)caller, event);
}

void CommandIterationUpdate::Execute(const ITKNS::Object * object, const ITKNS::EventObject & event)
{	
	ConstOptimizerPointer optimizer = 
		dynamic_cast< ConstOptimizerPointer >( object );
	if( ! ITKNS::IterationEvent().CheckEvent( &event ) )
	{
		return;
	}
	
	ParametersType params(6);
	params = optimizer->GetCurrentPosition();
	NSLog(@"Registration update, iteration: %d, metric: %f, transform params: %f %f %f %f %f %f", optimizer->GetCurrentIteration(), optimizer->GetValue(),
		  params[0], params[1], params[2], params[3], params[4], params[5]); 
	
	RegUpdate* update = [[RegUpdate alloc] initWithParams:params metricVal:optimizer->GetValue() iteration:optimizer->GetCurrentIteration()];
	[controller performSelectorOnMainThread:@selector(registrationUpdate:) withObject:update waitUntilDone:YES];

}

void CommandIterationUpdate::setDisplayObserver(PSFSettingsWindowController* observer)
{
	controller = observer;
}

void CommandIterationUpdate::stopRegistration()
{
	stopReg = true;
}
