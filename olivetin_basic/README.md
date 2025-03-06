## OliveTin  

https://www.olivetin.app/  
https://docs.olivetin.app/install/rpmdeb.html  

### Install on Linux directly  

```
wget https://github.com/OliveTin/OliveTin/releases/download/2025.2.21/OliveTin_linux_amd64.deb  
sudo dpkg -i OliveTin_linux_amd64.deb  
sudo systemctl enable --now OliveTin  
```

### Install with docker  

```
https://docs.olivetin.app/install/docker_compose.html  
```

### Configuration  
Basic `config.yml` in/as `/etc/OliveTin/config.yaml`

### Call action over API  
https://docs.olivetin.app/api/start_action.html  
`curl -X POST "http://olivetin.webapps.lan/api/StartAction" -d '{"actionId": "executeAll"}'`  

### Call API over NodeRED
```
[
    {
        "id": "703d727ff2895e7f",
        "type": "change",
        "z": "365f1b1d8c48fa99",
        "name": "",
        "rules": [
            {
                "t": "set",
                "p": "headers.Content-Type",
                "pt": "msg",
                "to": "application/json",
                "tot": "str"
            },
            {
                "t": "set",
                "p": "payload",
                "pt": "msg",
                "to": "\"{\\\"actionId\\\":\\\"checkLimits\\\"}\"",
                "tot": "json"
            }
        ],
        "action": "",
        "property": "",
        "from": "",
        "to": "",
        "reg": false,
        "x": 630,
        "y": 1340,
        "wires": [
            [
                "75d4963eaa884cf7"
            ]
        ]
    },
    {
        "id": "75d4963eaa884cf7",
        "type": "http request",
        "z": "365f1b1d8c48fa99",
        "name": "",
        "method": "POST",
        "ret": "obj",
        "paytoqs": "body",
        "url": "http://10.xxx.xxx.xxx:1337/api/StartAction",
        "tls": "",
        "persist": false,
        "proxy": "",
        "insecureHTTPParser": false,
        "authType": "",
        "senderr": false,
        "headers": [],
        "x": 770,
        "y": 1300,
        "wires": [
            [
                "2e00b0cd59429fe0"
            ]
        ]
    }
]
```