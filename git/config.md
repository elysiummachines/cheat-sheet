## **Windows global signing & ssh passphrase**

```sh
git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
git config --global gpg.ssh.program "C:/Windows/System32/OpenSSH/ssh-keygen.exe"
```
## **Check signing config**
```sh
git config --global gpg.format
git config --global commit.gpgsign
git config --global user.signingkey
git config --global gpg.ssh.program
```

## **Verify last commit was signed**
```sh
git log --show-signature -1
```

## **Check all global git config**
```sh
git config --global --list
```

## **Check remote URL**
```sh
git remote -v
```

## **Check local repo overrides**
```sh
git config --local --list
```
