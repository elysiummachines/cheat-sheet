## **Add key to agent**
```sh
ssh-add ~/.ssh/id_ed25519_github
```

## **Check SSH agent service**
```sh
Get-Service ssh-agent | Select Status, StartType
```

## **Start & enable SSH agent**
```sh
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent