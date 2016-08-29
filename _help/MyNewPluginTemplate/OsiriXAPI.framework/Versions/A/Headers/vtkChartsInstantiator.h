#ifndef __vtkChartsInstantiator_h
#define __vtkChartsInstantiator_h

#include "vtkInstantiator.h"



class VTK_CHARTS_EXPORT vtkChartsInstantiator
{
  public:
  vtkChartsInstantiator();
  ~vtkChartsInstantiator();
  private:
  static void ClassInitialize();
  static void ClassFinalize();
  static unsigned int Count;
}; 

static vtkChartsInstantiator vtkChartsInstantiatorInitializer;

#endif
