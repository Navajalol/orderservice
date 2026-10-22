WORKLOG: 
Environment: Ubuntu , .NET 8 SDK, version 20.10.18, Trivy 0.76.0.

Manual Redeploy run link: https://github.com/Navajalol/orderservice/actions/runs/39831769341 

WHAT WENT WRONG:

Issue: "APP_VERSION=1.0.0-test dotnet run &" not working 

Fix: noticed the original dotnet run & was still running in the background so I had to kill the instance using its PID and then run using the variable 

Using SharpZipLib version 1.2.0 and Newtonsoft.json version 9.0.1 for the vulnerable checks: Both newton soft have both High and Moderate severity 
vulnerable packages 

Issue: Docker Permission denied: 

Fix: Adding my computer user into the docker group so I do not have to user root using sudo usermod -aG docker $USER

Test links showing the gates are working successfully in a test environment: https://github.com/Navajalol/orderservice/pull/1, https://github.com/Navajalol/orderservice/pull/3;
Pull 1 failed at the format gate and pull 3 failed at the Trivy gate. 


QUESTIONS:

Question: why do we care if the container runs as root, and what did you have to change to make USER appuser actually work?

Answer: We care if the container runs on root because root has a much higher authorization on a setup than a user with less authority on the system. This means that
if the app is somehow compromised by malignant users, they will not be able to access system paths and wont be able to install malicious programs in that system.
With using "RUN adduser --disabled-password --gecos"" appuser" the user is created whenever the image is built and every container in the image runs as that user also I had to keep 
the app on port 8080 because non root users cant bind to ports below 1024.

Question: what's the actual risk of docker run with no restart policy and no health-based rollback, and what's the smallest
change that reduces it?

Answer: The risk of running docker with no restart policy is that if the app crashes is up to someone to notice the app is down and to manually redeploy it which could take longer if no
one is closely watching the deployment. The risk of having no health-based rollback means that whenever a new deploy happens, it stops and removes the previous one before we know the new
one is working properly. When that happens and the new deployment is not working properly, the system is not able to automatically rollback to the working version, so the application will
have downtime until someone manually redeploys the working version again, usually leading to a loss of profit. The smallest change would be to add a restart policy during the "run docker"
terminal so that anytime it crashes it will restart. The smallest change for the health-based rollback would be record the running image in a variable and then have it redeploy to that
image stored in the variable if the new deployment fails.

Question:Format check, test, security scan — if all three could run in parallel instead of sequentially, would you? What do you gain, what do you risk?

Answer: Yes, I would have them all run in parallel. When having the checks in parallel the run will be shorter since it will take as much time as the longest check, instead of every check
having to wait for the previous one. I am also able to get all the failures at once when having the checks in parallel, instead of having to fix one by one as they appear, I would be able
to fix them in bulk which in turn reduces the amount of time a successful deployment can take. Some of the risks are that since its running in parallel it will use more computing power and
can cause issues if there insufficient processing power for these checks.

Question: Where do secrets live in your pipeline? What's the blast radius if one leaks into a log line?

Answer: There are no secrets in my pipeline, the only credential being used is "GITHUB_TOKEN" which is built-in on GitHub. The token is created for each job and is revoked when the job ends.
If the token leaked into a log line the biggest issue would be if an attacker is able to obtain the push token where the attacker then can push malicious image onto the deployment.
However, the token only exist as the job is working so it would only be in a couple of minutes that the attack could happen.

Question: Your Trivy gate uses --ignore-unfixed. A base-image CVE that had no fix gets one next month. Nothing in your pipeline catches that automatically. What's the gap, how do you close it?

Answer: The gap happens because the image is only built and scanned when it is pused to main, if no one pushes anything to main for a long time the update will never be pushed onto main. A way to fix this is to have a daily rerun of the trivy gate against the image that is currently deployed to check for any updates and fixes. Then, we can schedule to update the image whenever it finds a difference between the current and new image.

Question: If this needed 3 replicas behind a load balancer instead of one docker run, what's the smallest realistic next step — and what would you explicitly not try to solve with a Dockerfile change alone?

Answer: The next smallest realistic step would be instead of using docker run everytime, I could use an orchestrator service where only the deploy changes, where it points to a new image and waits for the for it to come back stable. With this we can deploy new images with no downtime for the application which makes it very useful for scaling and rolling back. Any of the uses of the orchestrator that involves all 3 replicas I would not try to solve with a dockerfile change alone, so Load balancing, Deploys, Rollbacks, and configurations for each environment.



