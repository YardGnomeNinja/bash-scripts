#! /bin/bash

#Requires Docker container https://hub.docker.com/r/jimschubert/swagger-codegen-cli/
#Visit .NET website, grab form data, use form data to log in to website and save auth cookie, use auth cookie to visit Swagger doc page and save output to swagger.json, run Docker container to generate SDK from swagger.json 

loginpage="http://localhost:55896/p7/content/pgLogin.aspx"
swaggerpage="http://localhost:55896/p7/swagger/docs/v1"

#Navigate to and store Login Page
response=$(curl $loginpage)

#Locate VIEWSTATE value
viewstate_locate="__VIEWSTATE\" value=\"[[:alnum:]!#$%\&\'\(\)\*\+,-\./:\;\<=\>\?@\[\\\^_\`{|}~]+" 
[[ $response =~ $viewstate_locate ]]
viewstate_locate_output=$BASH_REMATCH
#echo $viewstate_locate_output

#Select only the VIEWSTATE value
viewstate_cleanup="[[:alnum:]!#$%\&\'\(\)\*\+,-\./:\;\<=\>\?@\[\\\^_\`{|}~]+$"
[[ $viewstate_locate_output =~ $viewstate_cleanup ]]
viewstate=$BASH_REMATCH
echo $viewstate

#Locate VIEWSTATEGENERATOR value
viewstategenerator_locate="__VIEWSTATEGENERATOR\"\ value=\"[[:alnum:]!#$%\&\'\(\)\*\+,-\./:\;\<=\>\?@\[\\\^_\`{|}~]+" 
[[ $response =~ $viewstategenerator_locate ]]
viewstategenerator_locate_output=$BASH_REMATCH
#echo $viewstategenerator_locate_output

#Select only the VIEWSTATEGENERATOR value
viewstategenerator_cleanup="[[:alnum:]!#$%\&\'\(\)\*\+,-\./:\;\<=\>\?@\[\\\^_\`{|}~]+$"
[[ $viewstategenerator_locate_output =~ $viewstategenerator_cleanup ]]
viewstategenerator=$BASH_REMATCH
#echo $viewstategenerator

#Sign in to site and generate cookie for Swagger request
curl -G -c cookie.txt -L $loginpage --data-urlencode "__VIEWSTATE="$viewstate --data-urlencode "txtUsername=chuck" --data-urlencode "txtPassword=notmyrealpassword" --data-urlencode "buttSubmit=Login" --data-urlencode "__VIEWSTATEGENERATOR="$viewstategenerator

#Navigate to Swagger page and generate swagger.json
curl -b cookie.txt -o swagger.json -L $swaggerpage

#Execute Swagger Codegen against swagger.json
docker run -it -v $PWD:/swagger-api/out jimschubert/swagger-codegen-cli generate -i /swagger-api/out/swagger.json -l csharp -c /swagger-api/out/sdkconfig.json -o /swagger-api/out/

#Clean up temp files
rm cookie.txt
rm swagger.json
