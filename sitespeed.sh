docker-compose run sitespeed.io --shm-size=1g --graphite.host=graphite -n 20 -d 999 https://carmencreek.azurewebsites.net/ \
&& docker-compose run sitespeed.io --shm-size=1g --graphite.host=graphite -n 20 -d 999 https://carmencreeklinux.azurewebsites.net/ \
&& docker-compose run sitespeed.io --shm-size=1g --graphite.host=graphite -n 20 -d 999 https://www.highplainsbison.com/ \
&& docker-compose run sitespeed.io --shm-size=1g --graphite.host=graphite -n 20 -d 999 https://highplainsbisonlinux.azurewebsites.net/


docker-compose run sitespeed.io --graphite.host=graphite -n 1 -d 999 https://carmencreek.azurewebsites.net/ 
&& docker-compose run sitespeed.io --graphite.host=graphite -n 1 -d 999 https://carmencreeklinux.azurewebsites.net/ 
&& docker-compose run sitespeed.io --graphite.host=graphite -n 1 -d 999 https://highplainsbison-qa.azurewebsites.net/ 
&& docker-compose run sitespeed.io --graphite.host=graphite -n 1 -d 999 https://highplainsbisonlinux.azurewebsites.net/