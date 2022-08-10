# SSL renew bot  

## Description  
I use letsencrypt-Certs only for internal use with internal DNS-Server.  
For letsencrypt I need a public DNS record.  
Most of the time the DNS record has an (non-functional) internal IP-Address and not routed in the internet.  
One time all 60 days, this script change it to the real address to renew the cert.  
The certbot in traefik make renew the certs, this script make the DNS requirement.  
After letsencrypt has expanded the expiry time, the IP-Address of the DNS record change bach to the internal.  

## Configuration and Credentials  
The cred.txt has credentials and configuration in it.  
It has to be configured with: (see also cred.txt.example)  
<Telegram-Bot-Token>  
<Telegram-Receiver>  
<DDNS-API-KEY>  
<Subdomain for DNS Update>  
<Maindomain for DNS Update>  
<Complete Domain for cert check = Subdomain + Maindomain>  
<Internal IP-Adress for Cert check (the real one, not the non-functional)>  

## Install as cronjob  
`18 * * * * /<your>/<workdir>/ssl_renew/ssl_check.sh > /tmp/ssl_last.log`
