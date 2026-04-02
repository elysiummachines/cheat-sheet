## **Commit with a custom date (Linux/WSL)**
```sh
export GIT_AUTHOR_DATE="YYYY-MM-DDTHH:MM:SS"
export GIT_COMMITTER_DATE="YYYY-MM-DDTHH:MM:SS"
echo $GIT_AUTHOR_DATE
echo $GIT_COMMITTER_DATE
git commit -m "message"
```

## **Amend last commit date (Linux/WSL)**
```sh
export GIT_AUTHOR_DATE="YYYY-MM-DDTHH:MM:SS"
export GIT_COMMITTER_DATE="YYYY-MM-DDTHH:MM:SS"
echo $GIT_AUTHOR_DATE
echo $GIT_COMMITTER_DATE
git commit --amend --reset-author -m "message"
```

## **Example - backdate commit to Sunday March 22 (Linux/WSL)**
```sh
export GIT_AUTHOR_DATE="2026-03-22T23:59:00"
export GIT_COMMITTER_DATE="2026-03-22T23:59:00"
echo $GIT_AUTHOR_DATE
echo $GIT_COMMITTER_DATE
git commit -m "docs: my commit message"
git log -1
```

---

## **Verify commit date**
```sh
git log -1
```

---

## **Commit with a custom date (PowerShell)**
```sh
$env:GIT_AUTHOR_DATE="YYYY-MM-DDTHH:MM:SS"
$env:GIT_COMMITTER_DATE="YYYY-MM-DDTHH:MM:SS"
echo $env:GIT_AUTHOR_DATE
echo $env:GIT_COMMITTER_DATE
git commit -m "message"
```

## **Amend last commit date (PowerShell)**
```sh
$env:GIT_AUTHOR_DATE="YYYY-MM-DDTHH:MM:SS"
$env:GIT_COMMITTER_DATE="YYYY-MM-DDTHH:MM:SS"
echo $env:GIT_AUTHOR_DATE
echo $env:GIT_COMMITTER_DATE
git commit --amend --reset-author -m "message"
```

## **Example - backdate commit to Sunday March 22 (PowerShell)**
```sh
$env:GIT_AUTHOR_DATE="2026-03-22T23:59:00"
$env:GIT_COMMITTER_DATE="2026-03-22T23:59:00"
echo $env:GIT_AUTHOR_DATE
echo $env:GIT_COMMITTER_DATE
git commit -m "docs: my commit message"
git log -1
```