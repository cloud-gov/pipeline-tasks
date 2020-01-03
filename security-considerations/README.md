# Security Considerations job

This is a concourse pipeline that checks to see that every pull
request has a Security Considerations section.


# Updating the job for repo changes
1. add/remove the repos as necessary in repos.txt
2. run `python generate-pipeline.py`
3. get the credentials file from our secrets store. Call it security-considerations.yml
4. run `fly -t fr sp -p security-considerations-check -c ./pipeline.yml -l cg-security-considerations.yml`

## making sure your PR passes
1. consider the security impacts of your changes
2. create a section in your PR that looks like this:
```
# Security Considerations
<whatever the considerations are, or a rationalization about why there are none>
```
The "security considerations" must be a heading, using the # syntax, but it can be any level of heading, and any capitalization you'd like
