#ifndef REGOBSERVER_H
#define REGOBSERVER_H

/**
 * \brief This class is responsible for keeping track of the registration process
 *
 * \authors Brian Jensen
 *          <br>
 *          {jensen}\@cs.tum.edu
 * \ingroup PetSpectFusion
 * \version 1.0
 * \date 16.04.2008
 *
 * \par License:
 * Copyright (c) 2007 - 2009,
 * This programm was created as part of a student research project in cooperation
 * with the Department for Computer Science, Chair XVI
 * and the Nuklearmedizinische Klinik, Klinikum Rechts der Isar
 *
 * <br>
 * <br>
 * All rights reserved.
 * <br>
 * <br>
 * See <a href="COPYRIGHT.txt">COPYRIGHT.txt</a> for details.
 * <br>
 * <br>
 * This software is distributed WITHOUT ANY WARRANTY; without even 
 * <br>
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
 * <br>
 * PURPOSE.  See the <a href="COPYRIGHT.txt">COPYRIGHT.txt</a> notice
 * for more information.
 *
 */

#import "Project_defs.h"

#define id Id
#include "itkCommand.h"
#include "itkVersorRigid3DTransformOptimizer.h"
#include "Typedefs.h"
#undef id

#import "RegUpdate.h"

@class PSFSettingsWindowController;

/**
 *	This class is an event observer that is called after each iteration of the registration process
 *
 */
class CommandIterationUpdate : public ITKNS::Command 
{
public:
	typedef  CommandIterationUpdate   Self;
	typedef  ITKNS::Command             Superclass;
	typedef ITKNS::SmartPointer<Self>  Pointer;
	itkNewMacro( Self );
	
	typedef ITKNS::VersorRigid3DTransformOptimizer     OptimizerType;
	typedef const OptimizerType *  ConstOptimizerPointer;
	typedef OptimizerType * OptimizerPointer;

private:
	//used for controlling the registration and updating the display
	bool stopReg;
	PSFSettingsWindowController* controller;
	
protected:
	CommandIterationUpdate()
	{ stopReg = false; };

public:

	/**
	 *	Called by the optimizer after each iteration
	 */
	void Execute(ITKNS::Object *caller, const ITKNS::EventObject & event);

	void Execute(const ITKNS::Object * object, const ITKNS::EventObject & event);
	
	/**
	 *	Sets the observer that should receive the registration updates
	 */
	void setDisplayObserver(PSFSettingsWindowController* observer);
	
	/**
	 *	Terminates the optimizer
	 */
	void stopRegistration();
	
};

/**
 *	This class is called after each level in the multiresolution registration
 *
 */
template <typename TRegistration>
class RegistrationInterfaceCommand : public ITKNS::Command 
{
	public:
	typedef  RegistrationInterfaceCommand	  Self;
	typedef  ITKNS::Command                   Superclass;
	typedef  ITKNS::SmartPointer<Self>        Pointer;
		itkNewMacro( Self );
	protected:
		RegistrationInterfaceCommand() {};

	private:
		PSFSettingsWindowController* controller;
	
	public:
		typedef   TRegistration RegistrationType;
		typedef   RegistrationType * RegistrationPointer;
		typedef   ITKNS::VersorRigid3DTransformOptimizer OptimizerType;
		typedef   OptimizerType * OptimizerPointer;

	/**
	 *	Called by the registration object after each level
	 */
	void Execute(ITKNS::Object * object, const ITKNS::EventObject & event)
	{
		if( !(ITKNS::IterationEvent().CheckEvent( &event )) )
		{
			return;
		}
		
		RegistrationPointer registration =
		dynamic_cast<RegistrationPointer>( object );
		
		NSLog(@"Current level: %d", registration->GetCurrentLevel());
		
		RegUpdate* update = [[RegUpdate alloc] initWithLevel:registration->GetCurrentLevel()];
		[controller performSelectorOnMainThread:@selector(levelChanged:) withObject:update waitUntilDone:NO];
	}
	
	/**
	 *	Sets the observer that should be notified after each level change
	 */
	void setDisplayObserver(PSFSettingsWindowController* observer)
	{
		controller = observer;
	}
	
	void Execute(const ITKNS::Object * , const ITKNS::EventObject & )
	{
		return;
	}
	
};

#endif
