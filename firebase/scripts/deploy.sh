DIR=$(pwd)
if [[ $DIR == */scripts ]];then
    cd ..
fi

firebase deploy