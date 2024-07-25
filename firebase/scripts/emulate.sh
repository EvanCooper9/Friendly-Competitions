DIR=$(pwd)
if [[ $DIR == */scripts ]];then
    cd ..
fi

cd functions && npm run build && cd .. && firebase emulators:start --import=exported-dev-data --export-on-exit=exported-dev-data
