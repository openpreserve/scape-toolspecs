#! /bin/bash

cd "$(dirname "$0")"

COUNT=0
OK=0

for TOOLSPEC in $(ls ../*.xml);
do
    COUNT=$((COUNT+1))
    xmllint --noout --schema ../schemas/tool-1.1_draft.xsd $TOOLSPEC
    if [ $? -eq 0 ]; then
        OK=$((OK+1))
    fi
done

echo
if [ $COUNT -eq $OK ]; then
    echo -e "\e[32mSUCCESS [$OK/$COUNT]\e[0m"
    exit 0
else
    FAILURES=$((COUNT-OK))
    echo -e "\e[31mFAILED [$FAILURES/$COUNT]\e[0m"
    exit 1
fi
