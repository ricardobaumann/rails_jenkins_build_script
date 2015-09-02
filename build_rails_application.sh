gem install --user-install bundler ;
gem install --user-install rails ;
gem install --user-install rake ;
bundle config build.nokogiri --use-system-libraries ;
bundle install ;

git checkout master && git pull
if [ -z "$releaseVersion" ] ; then
	echo "Creating integration branch 'integration/b${BUILD_NUMBER}'"
	git checkout -b integration/b${BUILD_NUMBER} master
else
	if [ "${finalRelease}" == "YES" ] ; then suffix="FINAL" ; else suffix="RC" ; fi
	releaseVersion="${releaseVersion}_${suffix}"
	echo "Creating release branch 'releases/${releaseVersion}'"
	git checkout -b releases/${releaseVersion} master
fi

echo "Merging branches..."
for BRANCH in `git branch -r --no-merged | grep -v "feature|develop" | xargs`; do
	echo "Merging branch $BRANCH"; 
	git merge -v $BRANCH || { git diff && git merge -v --abort && exit 1; };
done
RAILS_ENV=test rake db:create ;
RAILS_ENV=test rake db:migrate ;
rake test ; 

if ! [ -z "$releaseVersion" ] ; then
	echo "Releasing: ${releaseVersion}"
	git push origin releases/${releaseVersion}
	    if [ "${finalRelease}" == "YES" ] ; then
			git checkout master && git fetch --all
			git merge releases/${releaseVersion} || { git diff && git merge -v --abort && exit 1; };
			git tag -a "${releaseVersion}" -m "Release: ${releaseVersion}"
			git add -A . && git commit -m "Release: ${releaseVersion}"
			git push --tags origin master
			
			git checkout develop && git fetch --all
			git add -A . && git commit -m "Release: ${releaseVersion}"
			git merge releases/${releaseVersion} || { git diff && git merge -v --abort && exit 1; };
			git push origin develop
	    fi
    
fi
