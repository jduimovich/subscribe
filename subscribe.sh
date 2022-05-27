
# This script will create an argocd application for an AppStudio gitops repo
# It assumes the repo is layed out in the root and implementation details
# of where the files are... 
# You can use this to 
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO_URL=$1
if [ -z "$REPO_URL" ]; then 
    REPO_URL=$(git config --get remote.origin.url)
    if [ -n "$REPO_URL" ]; then
        echo "missing repo url and the current directory is not a git repo"
        exit 1.
    fi
fi 
REPO_NAME=$(basename $REPO_URL) 
  
ORG_NAME=${REPO_URL%$REPO_NAME} 
ORG_NAME=$(basename $ORG_NAME)  
PEEK_NS_FILE=https://raw.githubusercontent.com/$ORG_NAME/$REPO_NAME/main/common-storage-pvc.yaml

NS=$(curl --silent $PEEK_NS_FILE | yq '.metadata.namespace')
  
APPNAME=${REPO_NAME%-"$NS"*} 


echo "Repo: $REPO_URL"
echo "Name: $REPO_NAME"
echo "Org: $ORG_NAME"
echo "App: $APPNAME" 
echo "Namespace: $NS" 

yq e '.metadata.name="'$NS'"' $SCRIPTDIR/template/namespace.yaml | oc apply -f -   
oc project $NS  
yq e '.metadata.name="'$APPNAME'"' $SCRIPTDIR/template/application.yaml |
    yq e '.spec.destination.namespace="'$NS'"' - |   
    yq e '.spec.source.repoURL="'$REPO'"' - | 
    oc apply -f - 