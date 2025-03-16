## WebDAV-Server  

Deploy a WebDAV-Server with nginx and docker.  

### Installation  
- Copy `docker-compose.yml` and `default.conf` in your project-directory.  
- Generate `htpasswd` file:  
  `docker run --rm -ti xmartlabs/htpasswd <username> <password> > htpasswd`  
- Edit volume-paths in `docker-compose.yml`  
- Start with `docker compose up -d`  
- Open in Browser `http://localhost:8980`  