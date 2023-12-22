# FL notes about our customizations

## Master nginx template
To be able to dynamically write values to the nginx.tmpl file we maintain a master template `nginx.tmpl.master`.
This way we can add firewall rules etc.

## Server level firewall
In the staging environment it enhances security to be able to only allow selected IP addresses access for some hosts.
Add the hosts to protect to the `FIREWALL_PROTECTED_HOSTS` variable in the `.env` file as a comma separated list. 
Then add the IP addresses that are allowed access to the IP whitelist section in the `.env` file.

## Applying changes to firewall
To write the new values to the `nginx.tmpl`, run `./start.sh` script in the root folder. It is sometimes necessary to
restart the docker containers with

`docker restart nginx-gen`

and

`docker restart nginx-web`

## @todo - document other settings - php etc.
