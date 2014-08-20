#!/bin/bash

cd $(dirname $0)


if [ $# -eq 0 ]; then
	echo "Script that eases the generation of Debian packages for the toolspecs/components available in this GitHub repository"
	echo "(https://github.com/openplanets/scape-toolspecs)"
	echo
	echo "USAGE: $0 TOOLWRAPPER_BASE_DIR MAINTAINER_E-MAIL [TOOLSPECS_PATTERN]"
	echo
	echo "Example 1: Generate Debian packages for all toolspecs"
	echo "   $> $0 '/path/to/toolwrapper/base/dir' 'xpto@domain.com'"
	echo "Example 2: Generate Debian packages for migration toolspecs only"
	echo "   $> $0 '/path/to/toolwrapper/base/dir' 'xpto@domain.com' 'digital-preservation-migration*.xml'"
	exit 1
fi

TOOLSPECS_PATTERN="digital-preservation-migration*.xml"
EMAIL="xpto@domain.com"
TOOLWRAPPER_BASE_DIR="/home/hsilva/Git/scape-toolwrapper"
if [ $# -ge 2 ]; then
	TOOLWRAPPER_BASE_DIR="$1"
	EMAIL="$2"
fi
if [ $# -eq 3 ]; then
	TOOLSPECS_PATTERN="$3"
fi

TIME=$(date +%Y%m%dT%H%M%S)
DEBIANS_OUTPUT_DIR="../${TIME}_debians"
LOGFILE="../${TIME}_debians_generation.log"

if [ ! -d $DEBIANS_OUTPUT_DIR ]; then
	mkdir $DEBIANS_OUTPUT_DIR
fi
if [ -f $LOGFILE ]; then
	rm $LOGFILE
fi

for spec in $(ls ../$TOOLSPECS_PATTERN);
do
	operation=${spec/.xml/}
	operation_name=${operation/..\//}
	echo "Generating Debian package for \"$operation_name\"..."

	component="${operation}.component"
	changelog="${operation}.changelog"
	script="${operation}.sh"
	temp_dir=$(mktemp -d)

	# create bash wrapper and workflow
	$TOOLWRAPPER_BASE_DIR/toolwrapper-bash-generator/bin/generate.sh -t $spec -c $component -o $temp_dir &>>$LOGFILE
	
	if [ $? -eq 0 ]; then
		# create debian package
		if [ -f $script ]; then
			cp $script $temp_dir/install/
		fi
		$TOOLWRAPPER_BASE_DIR/toolwrapper-bash-debian-generator/bin/generate.sh -t $spec -i $temp_dir -o $temp_dir -e $EMAIL -ch $changelog &>>$LOGFILE

		if [ $? -eq 0 ]; then
			cp $temp_dir/debian/*.deb $DEBIANS_OUTPUT_DIR
			echo -e "\tDone!"
		else
			echo -e "\tError generating debian package for \"$operation_name\""
		fi

		rm -rf $temp_dir
	else
		echo -e "\tError generating bash wrapper and workflow for \"$operation_name\"!"
	fi
done
