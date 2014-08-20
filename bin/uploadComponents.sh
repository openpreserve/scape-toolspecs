#!/bin/bash

cd $(dirname $0)

if [ $# -eq 0 ]; then
	echo "Script that eases the upload of SCAPE Components generated from the toolspecs/components available in this GitHub repository"
	echo "(https://github.com/openplanets/scape-toolspecs)"
	echo
	echo "USAGE: $0 TOOLWRAPPER_BASE_DIR MYEXPERIMENT_USERNAME MYEXPERIMENT_PASSWORD [TOOLSPECS_PATTERN]"
	echo
	echo "Example 1: Uploading components for all toolspecs"
	echo "   $> $0 '/path/to/toolwrapper/base/dir' 'username' 'password'"
	echo "Example 2: Uploading components only for migration toolspecs"
	echo "   $> $0 '/path/to/toolwrapper/base/dir' 'username' 'password' 'digital-preservation-migration*.xml'"
	exit 1
fi

TOOLSPECS_PATTERN="digital-preservation-migration*.xml"
TOOLWRAPPER_BASE_DIR="/home/hsilva/Git/scape-toolwrapper"
if [ $# -ge 3 ]; then
	TOOLWRAPPER_BASE_DIR="$1"
	USERNAME="$2"
	PASSWORD="$3"
fi
if [ $# -eq 4 ]; then
	TOOLSPECS_PATTERN="$4"
fi

TIME=$(date +%Y%m%dT%H%M%S)
LOGFILE="../${TIME}_components_upload.log"

if [ -f $LOGFILE ]; then
	rm $LOGFILE
fi

for spec in $(ls ../$TOOLSPECS_PATTERN);
do
	operation=${spec/.xml/}
	operation_name=${operation/..\//}
	echo "Uploading components for \"$operation_name\"..."

	component="${operation}.component"
	changelog="${operation}.changelog"
	script="${operation}.sh"
	temp_dir=$(mktemp -d)

	description=$(egrep "<description>" "$spec" | head -n1 | sed 's#^\s\+<description>##;s#</description>$##')

	# create bash wrapper and workflow
	$TOOLWRAPPER_BASE_DIR/toolwrapper-bash-generator/bin/generate.sh -t $spec -c $component -o $temp_dir &>>$LOGFILE
	
	if [ $? -eq 0 ]; then

		component_family=$(echo "$operation_name" | sed 's#^digital-preservation-[a-zA-Z]\+-##;s#-.*$##')
		family="595"
		case $component_family in
			"audio")
				family="595"
			;;
			"video")
				family="595"
			;;
			"image")
				family="592"
			;;
			"office")
				family="601"
			;;
		esac

		# upload component (-e 490 to share with SCAPE group, -e public for public view/download) 
		$TOOLWRAPPER_BASE_DIR/toolwrapper-component-uploader/bin/upload.sh -c "$temp_dir/workflow/$operation_name.t2flow" -d "$description" -i "$family" -l Apache -p "$PASSWORD" -s "$temp_dir/install/$operation_name.component" -t "$temp_dir/install/$operation_name.xml" -u "$USERNAME" -e 490 &>>$LOGFILE
		#$TOOLWRAPPER_BASE_DIR/toolwrapper-component-uploader/bin/upload.sh -c "$temp_dir/workflow/$operation_name.t2flow" -d "$description" -i "$family" -l Apache -p "$PASSWORD" -s "$temp_dir/install/$operation_name.component" -t "$temp_dir/install/$operation_name.xml" -u "$USERNAME" -e public &>>$LOGFILE

		rm -rf $temp_dir
	else
		echo -e "\tError generating bash wrapper and workflow for \"$operation_name\"!" &>>$LOGFILE
	fi
done
