#!/bin/sh
#script for renaming the ikt namespace

echo $1
echo $2

if [ "$1" == "" ]; then echo "Usage: refactor_namespace.sh ITK_DIR NEW_NAMESPACE" && exit 1
fi

if [ -n "$2" ]; then NEWNAME=$2
else NEWNAME="psfITK"
fi

echo "Modifying Utiltlites/CMakeList.sys file, changing systems namespace"
sed -e "s/SET(KWSYS_NAMESPACE itksys)/SET(KWSYS_NAMESPACE ${NEWNAME}sys)/g" "$1/Utilities/CMakeLists.txt" > "$1/Utilities/CMakeLists.txt.sed"
test -s "$1/Utilities/CMakeLists.txt.sed" && (cmp -s "$1/Utilities/CMakeLists.txt.sed" "$1/Utilities/CMakeLists.txt" || mv -f "$1/Utilities/CMakeLists.txt.sed" "$1/Utilities/CMakeLists.txt")
echo "done\n"

echo "Modifying Code/IO/CMakeLists.txt, deavtivating test driver"
cp "$1/Code/IO/CMakeLists.txt" "$1/Code/CMakeLists.txt.original"
sed -e '/ADD_EXECUTABLE(itkTestDriver itkTestDriver.cxx)/,/CACHE INTERNAL \"itkTestDriver path to be used by subprojects\")/d' \
	"$1/Code/IO/CMakeLists.txt" > "$1/Code/IO/CMakeLists.txt.sed" 
test -s "$1/Code/IO/CMakeLists.txt.sed" && (cmp -s "$1/Code/IO/CMakeLists.txt.sed" "$1/Code/IO/CMakeLists.txt" || mv -f "$1/Code/IO/CMakeLists.txt.sed" "$1/Code/IO/CMakeLists.txt")	
echo "done"

FILELIST=`find $1 \( -name "*.h" -o -name "*.txx" -o -name "*.cxx" -o -name "*.hxx"  \) -print`

#echo "$FILELIST"

for i in $FILELIST; do
	echo "Changing $i ..."
	sed -e "s/namespace[ \t*]itk/namespace $NEWNAME/g" -e "s/::itk/::$NEWNAME/g" -e "s/itk::/$NEWNAME::/g" -e "s/itksys/${NEWNAME}sys/g" "$i" > "$i.sed"
	#cat "$i.sed"
	test -s "$i.sed" &&  (cmp -s "$i.sed" "$i" || mv -f "$i.sed" "$i")
	rm -f "$i.sed"
	echo "done\n"
	
done