#!/bin/sh

BASE=${PWD}
cd ..
OUTPUT=`pwd`
cd ${BASE}

echo "Installing dependencies using shell"
echo "Current path is: ${BASE}"
echo "Output path is: ${OUTPUT}"

echo "Build collection:"
ansible-galaxy collection build --force --output-path=${OUTPUT}/ ./
ls -latr ${OUTPUT}/*.tar.gz
ls -latr ${OUTPUT}/

echo "Installing collection:"
for i in `ls  ${OUTPUT}/*.tar.gz`
do
    ansible-galaxy collection install --force ${i}
    ansible-galaxy collection install --force -p ~/.ansible/collections  ${i}
done

# echo "Installing roles:"
# mkdir -p ${HOME}/.ansible/roles
# cp -r ${BASE}/../roles/* ${HOME}/.ansible/roles/
# ls -latr ${HOME}/.ansible/roles/
