DIR=$(pwd)
if [[ $DIR == */scripts ]];then
    cd ..
fi

cd functions && npm run lint && cd ..